using Deep.Client.Shared.Services;
using Deep.Client.Shared.Services.ContactV2;

namespace Deep.Cli;

internal static class AttachmentFiles
{
    internal static void RequireNoLinks(string path)
    {
        for (var cursor = Path.GetFullPath(path); cursor is not null; cursor = Path.GetDirectoryName(cursor))
            if (Path.Exists(cursor) && (File.GetAttributes(cursor) & FileAttributes.ReparsePoint) != 0)
                throw new IOException("Attachment link rejected.");
    }

    internal static async Task<object> DownloadAsync(CommandLine command, DeepIdV2AccountService accounts,
        DeepIdV2Conversation conversation, DeepIdV2ContactPathAuthoritySource source, CancellationToken ct)
    {
        var target = Path.GetFullPath(command.Output!); RequireNoLinks(target);
        if (Path.Exists(target)) throw new IOException("Attachment output already exists.");
        var parent = Path.GetDirectoryName(target)!;
        if (!Directory.Exists(parent)) throw new IOException("Attachment output directory must already exist.");
        var stage = Path.Combine(parent, ".deep-verified-download-" + Guid.NewGuid().ToString("N"));
        try
        {
            DeepIdV2DownloadedAttachment result;
            await using (var stream = new FileStream(stage, FileMode.CreateNew, FileAccess.Write, FileShare.None, 4096, FileOptions.WriteThrough))
            {
                result = await accounts.DownloadAttachmentAsync(conversation, Convert.FromHexString(command.Logical!),
                    Convert.FromHexString(command.Device!), stream, source, ct);
                await stream.FlushAsync(ct); stream.Flush(true);
            }
            ct.ThrowIfCancellationRequested(); RequireNoLinks(target); RequireNoLinks(stage);
            File.Move(stage, target, overwrite: false);
            return new { status = "downloaded", result.Bytes, result.PlaintextSha256, result.MediaType };
        }
        finally { if (File.Exists(stage)) { RequireNoLinks(stage); File.Delete(stage); } }
    }
}
