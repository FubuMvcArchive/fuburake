using NUnit.Framework;
using FubuTestingSupport;

namespace Other.Tests
{
    [TestFixture]
    public class SuccessfulTester
    {
        [Test]
        public void working()
        {
            true.ShouldBeTrue();
        }
    }
}