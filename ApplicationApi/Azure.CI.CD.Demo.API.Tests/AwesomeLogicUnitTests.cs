using System;
using Xunit;
using Azure.CI.CD.Demo.API.BusinessLogic;
using Azure.CI.CD.Demo.API.Data.Models;

namespace Azure.CI.CD.Demo.API.Tests
{
    public class AwesomeLogicUnitTests
    {
        [Fact]
        public void BestValueIs42ByDefault()
        {
            Assert.Equal(42, AwesomeLogic.BestValue(null));
            Assert.Equal(42, AwesomeLogic.BestValue(new Value[] {}));
            Assert.Equal(42, AwesomeLogic.BestValue(new Value[] {new Value()}));
        }

        [Fact]
        public void GetsOnlyValue()
        {
            Value val = new Value(){
                IntValue = 13
            };
            Assert.Equal(13, AwesomeLogic.BestValue(new Value[] {val}));
        }

        [Fact]
        public void GetsHighestValue()
        {
            Value val1 = new Value(){
                IntValue = 13
            };
            Value val2 = new Value(){
                IntValue = 78
            };
            Assert.Equal(78, AwesomeLogic.BestValue(new Value[] {val1, val2}));
            Assert.Equal(78, AwesomeLogic.BestValue(new Value[] {val2, val1}));
        }
    }
}
