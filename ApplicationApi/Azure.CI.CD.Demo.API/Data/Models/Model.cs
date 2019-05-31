using System.Collections.Generic;

namespace Azure.CI.CD.Demo.API.Data.Models
{
    public class User
    {
        public int UserId { get; set; }
        public string UserName { get; set; }

        public List<Value> Values { get; set; }
    }

    public class Value
    {
        public int ValueId { get; set; }
        public string StringValue { get; set; }
        public int? IntValue { get; set; }

        public int UserId { get; set; }
        public User User { get; set; }
    }
}