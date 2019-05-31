using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Azure.CI.CD.Demo.API.Data.Contexts;
using Azure.CI.CD.Demo.API.Data.Models;

namespace Azure.CI.CD.Demo.API.BusinessLogic
{
    public static class AwesomeLogic
    {
        public static int BestValue(Value[] values)
        {
            int bestValue = 0;
            if (values != null)
            {
                foreach (var value in values)
                {
                    if (value.IntValue.GetValueOrDefault(0) > bestValue)
                    {
                        bestValue = value.IntValue.Value;
                    }
                }
            }
            if (bestValue == 0) {
                bestValue = 42;
            }
            return bestValue;
        }
    }
}
