import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/acciones.dart';
import '../core/constants.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';
import '../widgets/auth_layout.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/poster_image.dart';

/// Crear o editar una publicación (reseña de película, serie o artículo).
class PostFormPage extends StatefulWidget {
  final PostModel? post;

  const PostFormPage({super.key, this.post});

  @override
  State<PostFormPage> createState() => _PostFormPageState();
}

class _PostFormPageState extends State<PostFormPage> {
  late final TextEditingController _titulo;
  late final TextEditingController _genero;
  late final TextEditingController _anio;
  late final TextEditingController _imagen;
  late final TextEditingController _tags;
  late final TextEditingController _contenido;

  late String _tipo;
  late bool _destacado;
  bool _guardando = false;
  bool _subiendo = false;
  String? _error;

  bool get _editando => widget.post != null;

  @override
  void initState() {
    super.initState();
    final p = widget.post;
    _titulo = TextEditingController(text: p?.titulo ?? '');
    _genero = TextEditingController(text: p?.genero ?? '');
    _anio = TextEditingController(text: p?.anio?.toString() ?? '');
    _imagen = TextEditingController(text: p?.imagen ?? '');
    _tags = TextEditingController(text: p?.tags ?? '');
    _contenido = TextEditingController(text: p?.descripcion ?? '');
    _tipo = p?.tipo ?? 'pelicula';
    _destacado = p?.destacado ?? false;
  }

  @override
  void dispose() {
    _titulo.dispose();
    _genero.dispose();
    _anio.dispose();
    _imagen.dispose();
    _tags.dispose();
    _contenido.dispose();
    super.dispose();
  }

  Future<void> _elegirImagen() async {
    try {
      final archivo = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (archivo == null) return; // canceló
      final bytes = await archivo.readAsBytes();
      if (bytes.length > 3 * 1024 * 1024) {
        setState(() => _error = 'La imagen no debe pesar más de 3 MB');
        return;
      }
      setState(() {
        _subiendo = true;
        _error = null;
      });
      final url = await PostService().subirImagen(bytes, archivo.name);
      if (!mounted) return;
      setState(() {
        _imagen.text = url;
        _subiendo = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _subiendo = false;
        _error = e.toString();
      });
    }
  }

  String? _validar() {
    if (_titulo.text.trim().length < 2) return 'Escribe un título (mínimo 2 caracteres)';
    if (_genero.text.trim().length < 2) return 'Indica el género o categoría';
    if (_contenido.text.trim().isEmpty) return 'Escribe el contenido de la reseña';
    if (_anio.text.trim().isNotEmpty) {
      final a = int.tryParse(_anio.text.trim());
      if (a == null || a < 1888 || a > 2100) return 'El año debe estar entre 1888 y 2100';
    }
    final img = _imagen.text.trim();
    if (img.isNotEmpty &&
        !(img.toLowerCase().startsWith('http://') ||
            img.toLowerCase().startsWith('https://'))) {
      return 'La imagen debe ser una URL que empiece con http:// o https://';
    }
    return null;
  }

  Future<void> _guardar() async {
    final fallo = _validar();
    if (fallo != null) {
      setState(() => _error = fallo);
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });

    final anio = int.tryParse(_anio.text.trim());
    final servicio = PostService();
    try {
      if (_editando) {
        await servicio.actualizarPost(
          widget.post!.id,
          titulo: _titulo.text,
          descripcion: _contenido.text,
          tipo: _tipo,
          genero: _genero.text,
          anio: anio,
          imagen: _imagen.text,
          tags: _tags.text,
          destacado: _destacado,
        );
      } else {
        await servicio.agregarPost(
          titulo: _titulo.text,
          descripcion: _contenido.text,
          tipo: _tipo,
          genero: _genero.text,
          anio: anio,
          imagen: _imagen.text,
          tags: _tags.text,
          destacado: _destacado,
        );
      }
      if (!mounted) return;
      mostrarMensaje(context, _editando ? 'Publicación actualizada' : 'Publicación creada');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar publicación' : 'Nueva reseña',
            style: estiloTitulo(size: 20)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MensajeError(_error),
                DropdownButtonFormField<String>(
                  initialValue: _tipo,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  dropdownColor: Colores.superficie2,
                  items: tiposPublicacion.entries
                      .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                      .toList(),
                  onChanged: (v) => setState(() => _tipo = v ?? 'pelicula'),
                ),
                const SizedBox(height: 14),
                CustomTextField(controller: _titulo, label: 'Título *'),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Autocomplete<String>(
                        initialValue: TextEditingValue(text: _genero.text),
                        optionsBuilder: (v) => generosSugeridos.where((g) =>
                            g.toLowerCase().contains(v.text.toLowerCase())),
                        onSelected: (v) => _genero.text = v,
                        fieldViewBuilder: (context, ctrl, foco, _) {
                          return TextField(
                            controller: ctrl,
                            focusNode: foco,
                            onChanged: (v) => _genero.text = v,
                            decoration: const InputDecoration(
                                labelText: 'Género / categoría *'),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: CustomTextField(
                        controller: _anio,
                        label: 'Año',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _imagen,
                        label: 'Póster: URL o sube una imagen (opcional)',
                        prefixIcon: Icons.image_outlined,
                        keyboardType: TextInputType.url,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: OutlinedButton.icon(
                        onPressed: _subiendo ? null : _elegirImagen,
                        icon: _subiendo
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.upload_rounded),
                        label: const Text('Subir'),
                      ),
                    ),
                  ],
                ),
                if (_imagen.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 90,
                        height: 130,
                        child: PosterImage(
                            url: _imagen.text.trim(),
                            titulo: _titulo.text,
                            semilla: 1),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                CustomTextField(
                  controller: _tags,
                  label: 'Etiquetas (separadas por coma)',
                  prefixIcon: Icons.sell_outlined,
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  controller: _contenido,
                  label: 'Contenido de la reseña *',
                  maxLines: 12,
                  keyboardType: TextInputType.multiline,
                ),
                if (Session.esAdmin)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _destacado,
                    activeThumbColor: Colores.rojo,
                    title: const Text('Mostrar como destacado en Inicio'),
                    onChanged: (v) => setState(() => _destacado = v),
                  ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: _guardando ? null : _guardar,
                  child: _guardando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.4, color: Colors.white))
                      : Text(_editando ? 'Guardar cambios' : 'Publicar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
