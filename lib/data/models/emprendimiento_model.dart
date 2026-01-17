class Emprendimiento {
  final int id;
  final String nombre;
  final String parroquia;
  final String sector;
  final String telefono;
  final String email;
  final String propietario;
  final String tipoTurismo;
  final int experiencia;
  final String asociacion;
  final String ruc;
  final String estadoLocal;
  final String serviciosProduccion;
  final String licenciaGadLoja;
  final String arcsa;
  final String turismo;
  final String equipos;
  final String paginaWeb;
  final String facebook;
  final String instagram;
  final String tiktok;
  final String whatsapp;
  final String tipo;
  final int mesas;
  final int plazas;
  final String banio;
  final String complementarios;
  final String oferta;
  final String? menu;
  final String tipoServicio;
  final double precioPromedio;
  final String procesos;
  final String materiaPrima;
  final String proveedores;
  final int numeroProveedores;
  final int numeroMujeres;
  final int numeroHombres;
  final int tiempoTrabajando;
  final String personalCapacitado;
  final String frecuenciaCapacitacion;
  final String dependenciaIngresos;
  final String genero;
  final String nivelEducacion;
  final int edad;
  final String estadoCivil;
  final double longitude;
  final double latitude;
  final String horario;
  final String categoria;
  final String photoUrl;
  final String? videoUrl;
  final List<String> galleryUrls;
  
  // Additional fields for UI
  final int likesCount;
  final int commentsCount;
  final int ratingCount;
  final double averageRating;
  final bool isFavoritedByUser;
  final bool isLikedByUser;

  Emprendimiento ({
    required this.id,
    required this.nombre,
    required this.parroquia,
    required this.sector,
    required this.telefono,
    required this.email,
    required this.propietario,
    required this.tipoTurismo,
    required this.experiencia,
    required this.asociacion,
    required this.ruc,
    required this.estadoLocal,
    required this.serviciosProduccion,
    required this.licenciaGadLoja,
    required this.arcsa,
    required this.turismo,
    required this.equipos,
    required this.paginaWeb,
    required this.facebook,
    required this.instagram,
    required this.tiktok,
    required this.whatsapp,
    required this.tipo,
    required this.mesas,
    required this.plazas,
    required this.banio,
    required this.complementarios,
    required this.oferta,
    this.menu,
    required this.tipoServicio,
    required this.precioPromedio,
    required this.procesos,
    required this.materiaPrima,
    required this.proveedores,
    required this.numeroProveedores,
    required this.numeroMujeres,
    required this.numeroHombres,
    required this.tiempoTrabajando,
    required this.personalCapacitado,
    required this.frecuenciaCapacitacion,
    required this.dependenciaIngresos,
    required this.genero,
    required this.nivelEducacion,
    required this.edad,
    required this.estadoCivil,
    required this.longitude,
    required this.latitude,
    required this.horario,
    required this.categoria,
    required this.photoUrl,
    this.videoUrl,
    required this.galleryUrls,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.ratingCount = 0,
    this.averageRating = 0.0,
    this.isFavoritedByUser = false,
    this.isLikedByUser = false,
  });

  factory Emprendimiento.fromJson(Map<String, dynamic> json) {
    return Emprendimiento(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      parroquia: json['parroquia'] ?? '',
      sector: json['sector'] ?? '',
      telefono: json['telefono'] ?? '',
      email: json['email'] ?? '',
      propietario: json['propietario'] ?? '',
      tipoTurismo: json['tipo_turismo'] ?? '',
      experiencia: json['experiencia'] ?? 0,
      asociacion: json['asociacion'] ?? 'No',
      ruc: json['ruc'] ?? 'No',
      estadoLocal: json['estado_local'] ?? 'Propio',
      serviciosProduccion: json['servicios_produccion'] ?? '',
      licenciaGadLoja: json['licencia_gad_loja'] ?? 'No',
      arcsa: json['arcsa'] ?? 'No',
      turismo: json['turismo'] ?? 'No',
      equipos: json['equipos'] ?? '',
      paginaWeb: json['pagina_web'] ?? 'No',
      facebook: json['facebook'] ?? 'No',
      instagram: json['instagram'] ?? 'No',
      tiktok: json['tiktok'] ?? 'No',
      whatsapp: json['whatsapp'] ?? 'No',
      tipo: json['tipo'] ?? '',
      mesas: json['mesas'] ?? 0,
      plazas: json['plazas'] ?? 0,
      banio: json['banio'] ?? 'No',
      complementarios: json['complementarios'] ?? '',
      oferta: json['oferta'] ?? '',
      menu: json['menu'],
      tipoServicio: json['tipo_servicio'] ?? '',
      precioPromedio: double.tryParse(json['precio_promedio'].toString()) ?? 0.0,
      procesos: json['procesos'] ?? '',
      materiaPrima: json['materia_prima'] ?? '',
      proveedores: json['proveedores'] ?? '',
      numeroProveedores: json['numero_proveedores'] ?? 0,
      numeroMujeres: json['numero_mujeres'] ?? 0,
      numeroHombres: json['numero_hombres'] ?? 0,
      tiempoTrabajando: json['tiempo_trabajando'] ?? 0,
      personalCapacitado: json['personal_capacitado'] ?? 'No',
      frecuenciaCapacitacion: json['frecuencia_capacitacion'] ?? '',
      dependenciaIngresos: json['dependencia_ingresos'] ?? '',
      genero: json['genero'] ?? 'Otro',
      nivelEducacion: json['nivel_educacion'] ?? 'No especificado',
      edad: json['edad'] ?? 0,
      estadoCivil: json['estado_civil'] ?? '',
      longitude: double.tryParse(json['longitude'].toString()) ?? 0.0,
      latitude: double.tryParse(json['latitude'].toString()) ?? 0.0,
      horario: json['horario'] ?? '',
      categoria: json['categoria'] ?? '',
      photoUrl: json['photo_url'] ?? 'https://picsum.photos/300/200',
      videoUrl: json['video_url'],
      galleryUrls: List<String>.from(json['gallery_urls'] ?? []),
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      ratingCount: json['rating_count'] ?? 0,
      averageRating: double.tryParse(json['average_rating'].toString()) ?? 0.0,
      isFavoritedByUser: json['is_favorited_by_user'] ?? false,
      isLikedByUser: json['is_liked_by_user'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'parroquia': parroquia,
      'sector': sector,
      'telefono': telefono,
      'email': email,
      'propietario': propietario,
      'tipo_turismo': tipoTurismo,
      'experiencia': experiencia,
      'asociacion': asociacion,
      'ruc': ruc,
      'estado_local': estadoLocal,
      'servicios_produccion': serviciosProduccion,
      'licencia_gad_loja': licenciaGadLoja,
      'arcsa': arcsa,
      'turismo': turismo,
      'equipos': equipos,
      'pagina_web': paginaWeb,
      'facebook': facebook,
      'instagram': instagram,
      'tiktok': tiktok,
      'whatsapp': whatsapp,
      'tipo': tipo,
      'mesas': mesas,
      'plazas': plazas,
      'banio': banio,
      'complementarios': complementarios,
      'oferta': oferta,
      'menu': menu,
      'tipo_servicio': tipoServicio,
      'precio_promedio': precioPromedio,
      'procesos': procesos,
      'materia_prima': materiaPrima,
      'proveedores': proveedores,
      'numero_proveedores': numeroProveedores,
      'numero_mujeres': numeroMujeres,
      'numero_hombres': numeroHombres,
      'tiempo_trabajando': tiempoTrabajando,
      'personal_capacitado': personalCapacitado,
      'frecuencia_capacitacion': frecuenciaCapacitacion,
      'dependencia_ingresos': dependenciaIngresos,
      'genero': genero,
      'nivel_educacion': nivelEducacion,
      'edad': edad,
      'estado_civil': estadoCivil,
      'longitude': longitude,
      'latitude': latitude,
      'horario': horario,
      'categoria': categoria,
      'photo_url': photoUrl,
      'video_url': videoUrl,
      'gallery_urls': galleryUrls,
    };
  }

  String get categoryDisplayName {
    switch (categoria.toLowerCase()) {
      case '5 estrellas':
      case 'premium':
      case 'gold':
        return '⭐⭐⭐⭐⭐';
      case '4 estrellas':
      case 'platinum':
        return '⭐⭐⭐⭐';
      case '3 estrellas':
      case 'silver':
        return '⭐⭐⭐';
      case '2 estrellas':
      case 'bronze':
        return '⭐⭐';
      case '1 estrella':
      case 'basic':
        return '⭐';
      default:
        return categoria;
    }
  }

  int get categoryPriority {
    switch (categoria.toLowerCase()) {
      case '5 estrellas':
      case 'premium':
      case 'gold':
        return 5;
      case '4 estrellas':
      case 'platinum':
        return 4;
      case '3 estrellas':
      case 'silver':
        return 3;
      case '2 estrellas':
      case 'bronze':
        return 2;
      case '1 estrella':
      case 'basic':
        return 1;
      default:
        return 0;
    }
  }

  bool get hasMenu => menu != null && menu!.isNotEmpty;
  bool get hasVideo => videoUrl != null && videoUrl!.isNotEmpty;
  bool get hasGallery => galleryUrls.isNotEmpty;
  bool get hasLocation => latitude != 0.0 && longitude != 0.0;

  List<String> get socialMediaLinks {
    List<String> links = [];
    if (facebook == 'Sí') links.add('Facebook');
    if (instagram == 'Sí') links.add('Instagram');
    if (tiktok == 'Sí') links.add('TikTok');
    if (whatsapp == 'Sí') links.add('WhatsApp');
    return links;
  }

  Emprendimiento copyWith({
    int? likesCount,
    int? commentsCount,
    bool? isFavoritedByUser,
    bool? isLikedByUser,
    double? averageRating,
    int? ratingCount,
  }) {
    return Emprendimiento(
      id: id,
      nombre: nombre,
      parroquia: parroquia,
      sector: sector,
      telefono: telefono,
      email: email,
      propietario: propietario,
      tipoTurismo: tipoTurismo,
      experiencia: experiencia,
      asociacion: asociacion,
      ruc: ruc,
      estadoLocal: estadoLocal,
      serviciosProduccion: serviciosProduccion,
      licenciaGadLoja: licenciaGadLoja,
      arcsa: arcsa,
      turismo: turismo,
      equipos: equipos,
      paginaWeb: paginaWeb,
      facebook: facebook,
      instagram: instagram,
      tiktok: tiktok,
      whatsapp: whatsapp,
      tipo: tipo,
      mesas: mesas,
      plazas: plazas,
      banio: banio,
      complementarios: complementarios,
      oferta: oferta,
      menu: menu,
      tipoServicio: tipoServicio,
      precioPromedio: precioPromedio,
      procesos: procesos,
      materiaPrima: materiaPrima,
      proveedores: proveedores,
      numeroProveedores: numeroProveedores,
      numeroMujeres: numeroMujeres,
      numeroHombres: numeroHombres,
      tiempoTrabajando: tiempoTrabajando,
      personalCapacitado: personalCapacitado,
      frecuenciaCapacitacion: frecuenciaCapacitacion,
      dependenciaIngresos: dependenciaIngresos,
      genero: genero,
      nivelEducacion: nivelEducacion,
      edad: edad,
      estadoCivil: estadoCivil,
      longitude: longitude,
      latitude: latitude,
      horario: horario,
      categoria: categoria,
      photoUrl: photoUrl,
      videoUrl: videoUrl,
      galleryUrls: galleryUrls,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      ratingCount: ratingCount ?? this.ratingCount,
      averageRating: averageRating ?? this.averageRating,
      isFavoritedByUser: isFavoritedByUser ?? this.isFavoritedByUser,
      isLikedByUser: isLikedByUser ?? this.isLikedByUser,
    );
  }
}