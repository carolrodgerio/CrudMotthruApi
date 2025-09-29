using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace CrudMotthruApi;

[Table("motos")]
public class Moto
{
    [Key]
    [Column("id_moto")]
    public int Id { get; set; }

    [Required]
    [Column("placa")]
    [StringLength(10)]
    public string Placa { get; set; } = string.Empty;

    [Required]
    [Column("chassi")]
    [StringLength(50)]
    public string Chassi { get; set; } = string.Empty;
    
    [Column("num_motor")]
    [StringLength(50)]
    public string? NumMotor { get; set; }

    [Column("id_modelo")]
    public int IdModelo { get; set; }
    
    [Column("id_patio")]
    public int IdPatio { get; set; }
}