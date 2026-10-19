using System.Diagnostics;
using System.Reflection;

namespace Deep.Cli.Tests;

public sealed class BuildConfigurationTests
{
    [Theory]
    [InlineData("Deep.Client.Shared")]
    [InlineData("Deep.Protocol")]
    [InlineData("Deep.Protocol.MembershipRoutes")]
    [InlineData("Deep.Protocol.ProfileCarrier")]
    public void OwnedRuntimeOptimizationMatchesTheActualCliAssembly(string name)
    {
        // Inspect actual loaded producer assemblies, not an output directory
        // label. A Release console wrapping Debug Shared/Protocol must fail.
        var cli = typeof(CommandLine).Assembly;
        var dependency = Assembly.Load(new AssemblyName(name));
        Assert.Equal(name, dependency.GetName().Name);
        Assert.Equal(OptimizerDisabled(cli), OptimizerDisabled(dependency));
    }

    private static bool OptimizerDisabled(Assembly assembly) =>
        assembly.GetCustomAttribute<DebuggableAttribute>()?.IsJITOptimizerDisabled ?? false;
}
