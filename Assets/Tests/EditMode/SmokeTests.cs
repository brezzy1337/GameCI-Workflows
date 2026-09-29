using NUnit.Framework;

namespace GameCIWorkflows.Tests.EditMode
{
    // Day-one smoke test so CI (Unity Build Automation) has something to run.
    // Replace with real tests of plain C# / ScriptableObject logic as the project grows.
    public class SmokeTests
    {
        [Test]
        public void EditModeTestAssemblyIsWiredUp()
        {
            Assert.Pass("EditMode test assembly compiles and runs.");
        }
    }
}
