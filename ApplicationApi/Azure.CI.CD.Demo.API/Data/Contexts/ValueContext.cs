using Microsoft.EntityFrameworkCore;
using Azure.CI.CD.Demo.API.Data.Models;

namespace Azure.CI.CD.Demo.API.Data.Contexts
{
    public class ValueContext : DbContext
    {
        private readonly string _url;

        public ValueContext(DbContextOptions<ValueContext> options)
            : base(options)
        { }

        protected ValueContext(string url)
            : base()
        {
            _url = url;
        }

        public DbSet<User> Users { get; set; }
        public DbSet<Value> Values { get; set; }

        protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        {
            if (!string.IsNullOrEmpty(_url))
            {
                optionsBuilder.UseSqlServer(_url);
            }

            base.OnConfiguring(optionsBuilder);
        }
    }
}