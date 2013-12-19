using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Bottles.Services;
using FubuCore.CommandLine;

namespace FakeService
{
    public class FakeServiceLoader : IApplicationLoader, IDisposable
    {
        public IDisposable Load()
        {
            ConsoleWriter.Write(ConsoleColor.Green, "I'm starting");
            return this;
        }

        public void Dispose()
        {
            ConsoleWriter.Write(ConsoleColor.Green, "I'm shutting down");
        }
    }
}
