using Deep.Client.Shared.Persistence;

namespace Deep.Cli;

// Deltas of the storage owner's closed scalar counters. These are managed I/O
// acknowledgements, not physical-device traffic, authority or cached secrets.
internal static class SecureStorageWork
{
    internal static object Delta(DeepSecureStorageWorkSnapshot after, DeepSecureStorageWorkSnapshot before = default) => new
    {
        manifestReads = checked(after.ManifestReads - before.ManifestReads),
        manifestProtectedBytesRead = checked(after.ManifestProtectedBytesRead - before.ManifestProtectedBytesRead),
        manifestPlaintextBytesDecoded = checked(after.ManifestPlaintextBytesDecoded - before.ManifestPlaintextBytesDecoded),
        objectReads = checked(after.ObjectReads - before.ObjectReads),
        objectCiphertextBytesRead = checked(after.ObjectCiphertextBytesRead - before.ObjectCiphertextBytesRead),
        objectPlaintextBytesDecrypted = checked(after.ObjectPlaintextBytesDecrypted - before.ObjectPlaintextBytesDecrypted),
        manifestWrites = checked(after.ManifestWrites - before.ManifestWrites),
        manifestProtectedBytesWritten = checked(after.ManifestProtectedBytesWritten - before.ManifestProtectedBytesWritten),
        objectWrites = checked(after.ObjectWrites - before.ObjectWrites),
        objectCiphertextBytesWritten = checked(after.ObjectCiphertextBytesWritten - before.ObjectCiphertextBytesWritten),
        cleanupTombstones = checked(after.CleanupTombstones - before.CleanupTombstones),
        unprotectCalls = checked(after.UnprotectCalls - before.UnprotectCalls),
        protectCalls = checked(after.ProtectCalls - before.ProtectCalls)
    };
}
