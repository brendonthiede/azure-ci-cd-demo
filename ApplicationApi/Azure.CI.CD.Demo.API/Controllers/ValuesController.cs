using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Azure.CI.CD.Demo.API.Data.Contexts;
using Azure.CI.CD.Demo.API.Data.Models;

namespace Azure.CI.CD.Demo.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ValuesController : ControllerBase
    {
        private readonly ValueContext _dbContext;

        public ValuesController(ValueContext dbContext) {
            _dbContext = dbContext;
        }

        // GET api/values
        [HttpGet]
        public ActionResult<IEnumerable<Value>> Get()
        {
            var results = from value in _dbContext.Values
                          orderby value.ValueId
                          select value;
            return results.ToArray();
        }

        // GET api/values/5
        [HttpGet("{id}")]
        public ActionResult<Value> Get(int id)
        {
            var result = from value in _dbContext.Values
                          where value.ValueId.Equals(id)
                          select value;
            return result.FirstOrDefault();
        }

        // POST api/values
        [HttpPost]
        public void Post([FromBody] string value)
        {
        }

        // PUT api/values/5
        [HttpPut("{id}")]
        public void Put(int id, [FromBody] string value)
        {
        }

        // DELETE api/values/5
        [HttpDelete("{id}")]
        public void Delete(int id)
        {
        }
    }
}
