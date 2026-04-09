import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // ── Campos tabla Customer ──────────────────────────
  final _firstNameCtrl      = TextEditingController();
  final _secondNameCtrl     = TextEditingController();
  final _firstLastNameCtrl  = TextEditingController();
  final _secondLastNameCtrl = TextEditingController();
  final _phoneNumberCtrl    = TextEditingController();
  final _emailCtrl          = TextEditingController();

  // ── Campo tabla UserEntity ─────────────────────────
  final _addressCtrl        = TextEditingController();

  // ── Cambio de contraseña ───────────────────────────
  final _currentPasswordCtrl  = TextEditingController();
  final _newPasswordCtrl      = TextEditingController();
  final _confirmPasswordCtrl  = TextEditingController();

  bool _isLoading      = false;
  bool _showPasswords  = false;
  bool _changePassword = false;

  @override
  void initState() {
    super.initState();
    final user   = context.read<AuthProvider>().currentUser;
    final entity = user?.entity;

    _firstNameCtrl.text      = entity?.first_name      ?? '';
    _secondNameCtrl.text     = entity?.secondName      ?? '';
    _firstLastNameCtrl.text  = entity?.last_name       ?? '';
    _secondLastNameCtrl.text = entity?.secondLastName  ?? '';
    _phoneNumberCtrl.text    = entity?.phone           ?? '';
    _emailCtrl.text          = user?.username          ?? '';
    _addressCtrl.text        = entity?.address         ?? '';
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _secondNameCtrl.dispose();
    _firstLastNameCtrl.dispose();
    _secondLastNameCtrl.dispose();
    _phoneNumberCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();

    // Payload que coincide EXACTAMENTE con lo que espera el backend
    final data = <String, dynamic>{
      'firstName':      _firstNameCtrl.text.trim(),
      'secondName':     _secondNameCtrl.text.trim(),
      'firstLastName':  _firstLastNameCtrl.text.trim(),
      'secondLastName': _secondLastNameCtrl.text.trim(),
      'phoneNumber':    _phoneNumberCtrl.text.trim(),
      'email':          _emailCtrl.text.trim(),
      'address':        _addressCtrl.text.trim(),
    };

    // Añadir campos de contraseña solo si el usuario activó el cambio
    if (_changePassword && _newPasswordCtrl.text.isNotEmpty) {
      data['currentPassword']    = _currentPasswordCtrl.text;
      data['newPassword']        = _newPasswordCtrl.text;
      data['confirmNewPassword'] = _confirmPasswordCtrl.text;
    }

    final success = await auth.updateProfile(data);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Perfil actualizado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      final msg = auth.error ?? 'Error al actualizar el perfil';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    }
  }

  // ── Widget de campo ────────────────────────────────
  Widget _campo({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool obligatorio = false,
    bool esPassword  = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: esPassword && !_showPasswords,
        validator: validator ??
            (v) {
              if (obligatorio && (v == null || v.trim().isEmpty)) {
                return 'Este campo es obligatorio';
              }
              return null;
            },
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: esPassword
              ? IconButton(
                  icon: Icon(_showPasswords ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _showPasswords = !_showPasswords),
                )
              : null,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red),
          ),
        ),
      ),
    );
  }

  Widget _seccion(String titulo) => Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 10),
        child: Text(
          titulo,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
            letterSpacing: 0.3,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [Colors.blue, Colors.blue.shade200]),
                    ),
                    child: const CircleAvatar(
                      radius: 46,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 46, color: Colors.blue),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Tarjeta del formulario
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // ── NOMBRES ─────────────────────────────────────
                          _seccion('Nombres'),
                          _campo(
                            label: 'Primer nombre *',
                            controller: _firstNameCtrl,
                            icon: Icons.person,
                            obligatorio: true,
                          ),
                          _campo(
                            label: 'Segundo nombre',
                            controller: _secondNameCtrl,
                            icon: Icons.person_outline,
                          ),

                          // ── APELLIDOS ────────────────────────────────────
                          _seccion('Apellidos'),
                          _campo(
                            label: 'Primer apellido *',
                            controller: _firstLastNameCtrl,
                            icon: Icons.badge,
                            obligatorio: true,
                          ),
                          _campo(
                            label: 'Segundo apellido',
                            controller: _secondLastNameCtrl,
                            icon: Icons.badge_outlined,
                          ),

                          // ── CONTACTO ─────────────────────────────────────
                          _seccion('Contacto'),
                          _campo(
                            label: 'Correo electrónico *',
                            controller: _emailCtrl,
                            icon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'El correo es obligatorio';
                              if (!v.contains('@')) return 'Ingresa un correo válido';
                              return null;
                            },
                          ),
                          _campo(
                            label: 'Teléfono',
                            controller: _phoneNumberCtrl,
                            icon: Icons.phone,
                            keyboardType: TextInputType.phone,
                          ),
                          _campo(
                            label: 'Dirección',
                            controller: _addressCtrl,
                            icon: Icons.location_on,
                          ),

                          // ── CAMBIO DE CONTRASEÑA ─────────────────────────
                          const Divider(height: 28),
                          Row(
                            children: [
                              const Icon(Icons.lock, color: Colors.blue, size: 18),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Cambiar contraseña',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Switch(
                                value: _changePassword,
                                activeThumbColor: Colors.blue,
                                onChanged: (v) {
                                  setState(() {
                                    _changePassword = v;
                                    if (!v) {
                                      _currentPasswordCtrl.clear();
                                      _newPasswordCtrl.clear();
                                      _confirmPasswordCtrl.clear();
                                    }
                                  });
                                },
                              ),
                            ],
                          ),

                          if (_changePassword) ...[
                            const SizedBox(height: 6),
                            _campo(
                              label: 'Contraseña actual',
                              controller: _currentPasswordCtrl,
                              icon: Icons.lock_outline,
                              esPassword: true,
                              validator: (v) {
                                if (_changePassword && (v == null || v.isEmpty)) {
                                  return 'Ingresa tu contraseña actual';
                                }
                                return null;
                              },
                            ),
                            _campo(
                              label: 'Nueva contraseña',
                              controller: _newPasswordCtrl,
                              icon: Icons.lock,
                              esPassword: true,
                              validator: (v) {
                                if (_changePassword) {
                                  if (v == null || v.isEmpty) return 'Ingresa la nueva contraseña';
                                  if (v.length < 6) return 'Mínimo 6 caracteres';
                                }
                                return null;
                              },
                            ),
                            _campo(
                              label: 'Confirmar nueva contraseña',
                              controller: _confirmPasswordCtrl,
                              icon: Icons.lock,
                              esPassword: true,
                              validator: (v) {
                                if (_changePassword && v != _newPasswordCtrl.text) {
                                  return 'Las contraseñas no coinciden';
                                }
                                return null;
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 26),

                  // Botón guardar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _guardarCambios,
                      icon: const Icon(Icons.save),
                      label: const Text(
                        'Guardar cambios',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
