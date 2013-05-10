using NUnit.Framework;
using FubuTestingSupport;

namespace FubuRakeTarget.Testing
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