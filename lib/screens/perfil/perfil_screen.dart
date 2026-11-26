import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../core/app_strings.dart';
import '../../core/app_text_styles.dart';
import '../../models/usuario.dart';
import '../../providers/auth_provider.dart';
import '../../providers/perfil_provider.dart';
import '../../providers/role_provider.dart';
import '../../services/auth_logic/validaciones_auth.dart';
import '../../widgets/app_action_button.dart';
import '../../widgets/app_decorative_background.dart';
import '../../widgets/app_screen_header.dart';
import '../../widgets/contenido_centrado.dart';

/// Perfil de la persona que inició sesión. Va dentro del AppShell.
///
/// Muestra su nombre, su mail y su rol. El nombre se puede editar (se guarda en
/// la cuenta y en el documento de "usuarios"); el mail y el rol no: el mail es
/// el de la cuenta y el rol lo cambia un administrador desde Usuarios. Todos los
/// roles pueden ver esta pantalla. También tiene el botón para cerrar sesión.
class PerfilScreen extends ConsumerStatefulWidget {
  const PerfilScreen({super.key});

  @override
  ConsumerState<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends ConsumerState<PerfilScreen> {
  final _nombre = TextEditingController();

  // Si la persona ya tocó el campo, un cambio del documento no le pisa lo que
  // está escribiendo.
  bool _editado = false;
  bool _guardando = false;
  String? _errorNombre;

  @override
  void initState() {
    super.initState();
    ref.listenManual<AsyncValue<Usuario?>>(
      perfilUsuarioProvider,
      (previous, next) => _traerNombre(next.value),
      fireImmediately: true,
    );
  }

  void _traerNombre(Usuario? usuario) {
    if (_editado || usuario == null) return;
    _nombre.text = usuario.nombre;
  }

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final perfil = ref.watch(perfilUsuarioProvider);
    final rol = ref.watch(roleProvider);
    // El mail es el de la cuenta de Firebase, no el del documento.
    final email = ref.watch(authServiceProvider).emailActual ??
        perfil.value?.email ??
        '';

    return ColoredBox(
      color: AppColors.screenBackground,
      child: AppDecorativeBackground(
        child: SafeArea(
          bottom: false,
          child: ContenidoCentrado(
            child: Column(
              children: [
                AppScreenHeader(
                  title: AppStrings.perfilTitulo,
                  onBack: () => _volver(context),
                ),
                Expanded(
                  child: perfil.hasError && !perfil.hasValue
                      ? Center(
                          child: Text(
                            AppStrings.perfilError,
                            style: AppTextStyles.listItemSubtitle,
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(36, 16, 36, 24),
                          children: [
                            TextField(
                              controller: _nombre,
                              enabled: !_guardando,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.done,
                              decoration: InputDecoration(
                                labelText: AppStrings.perfilNombre,
                                errorText: _errorNombre,
                                filled: true,
                                fillColor: AppColors.inputBackground,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onChanged: (_) => setState(() {
                                _editado = true;
                                _errorNombre = null;
                              }),
                              onSubmitted: (_) => _guardar(),
                            ),
                            const SizedBox(height: 16),
                            _DatoFijo(
                              etiqueta: AppStrings.perfilEmail,
                              valor: email,
                            ),
                            const SizedBox(height: 12),
                            _DatoFijo(
                              etiqueta: AppStrings.perfilRol,
                              valor: AppStrings.usuariosRol(rol),
                            ),
                            const SizedBox(height: 28),
                            AppActionButton(
                              label: AppStrings.perfilGuardarNombre,
                              onPressed: _guardando ? null : _guardar,
                            ),
                            const SizedBox(height: 16),
                            AppActionButton(
                              label: AppStrings.perfilCerrarSesion,
                              variant: AppActionButtonVariant.secondary,
                              onPressed: _cerrarSesion,
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _guardar() async {
    if (_guardando) return;
    final nombre = _nombre.text;
    // Se avisa en el mismo campo, sin ir a Firebase.
    if (!ValidacionesAuth.esNombreValido(nombre)) {
      setState(() => _errorNombre = ValidacionesAuth.avisoNombre);
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _guardando = true);
    try {
      final guardado = await ref.read(perfilAccionesProvider).cambiarNombre(nombre);
      if (!mounted) return;
      // El campo queda con el nombre limpio y vuelve a seguir al documento.
      _nombre.text = guardado;
      _editado = false;
      messenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.perfilNombreActualizado)),
      );
    } on NombreRechazadoException catch (e) {
      if (!mounted) return;
      // Si la cuenta no lo guardó, AuthService ya mostró el motivo.
      if (e.motivo != MotivoNombreRechazado.noSeGuardoEnLaCuenta) {
        messenger.showSnackBar(
          const SnackBar(content: Text(AppStrings.perfilErrorNombre)),
        );
      }
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.perfilErrorNombre)),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  // El router lleva solo a la pantalla de acceso cuando la sesión se cierra.
  Future<void> _cerrarSesion() => ref.read(authServiceProvider).signOut();

  // Si se llegó desde otra pantalla vuelve atrás; si no (por ejemplo desde la
  // barra inferior), vuelve a Inventario.
  void _volver(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/inventario');
    }
  }
}

/// Un dato que se muestra pero no se edita (mail y rol).
class _DatoFijo extends StatelessWidget {
  const _DatoFijo({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.subtleSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outlineColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiqueta, style: AppTextStyles.itemDetail),
          const SizedBox(height: 2),
          Text(valor, style: AppTextStyles.listItemTitle),
        ],
      ),
    );
  }
}
