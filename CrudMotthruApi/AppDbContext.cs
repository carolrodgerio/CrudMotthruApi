using Microsoft.EntityFrameworkCore;

namespace CrudMotthruApi;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
    {
    }

    public DbSet<Moto> Motos { get; set; }
}