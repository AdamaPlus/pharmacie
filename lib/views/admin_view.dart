import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../models/pharmacy_models.dart';

class AdminView extends StatefulWidget {
  const AdminView({super.key});

  @override
  State<AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends State<AdminView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final themeColor = const Color(0xFF10B981);

    return Scaffold(
      backgroundColor: state.bgPrimary,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Subheader row (No tabs, just title and add button)
          Container(
            color: state.bgSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: Row(
              children: [
                Text(
                  'Gestion des Comptes Vendeurs',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: state.textPrimary,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showAddUserDialog(context, state),
                  icon: const Icon(Icons.person_add_rounded, size: 18),
                  label: const Text('Ajouter un Vendeur'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),

          // Main body: list of vendors
          Expanded(
            child: _buildUsersTab(state, themeColor),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // USERS ACCOUNTS LIST (Excluding ADMIN)
  // ==========================================
  Widget _buildUsersTab(AppStateProvider state, Color themeColor) {
    // Exclude users with role ADMIN
    final vendors = state.users.where((u) => u.role != 'ADMIN').toList();

    if (vendors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline_rounded, size: 64, color: state.textSecondaryLight),
            const SizedBox(height: 16),
            Text(
              'Aucun compte vendeur n\'a été créé.',
              style: GoogleFonts.inter(color: state.textSecondary, fontSize: 15, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Cliquez sur "Ajouter un Vendeur" pour commencer.',
              style: GoogleFonts.inter(color: state.textSecondaryLight, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(32),
      itemCount: vendors.length,
      itemBuilder: (context, idx) {
        final u = vendors[idx];
        return Card(
          color: state.bgSecondary,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: state.borderTheme),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: themeColor.withOpacity(0.1),
                  backgroundImage: (u.profileImageBase64 != null && u.profileImageBase64!.isNotEmpty)
                      ? MemoryImage(base64Decode(u.profileImageBase64!))
                      : null,
                  child: (u.profileImageBase64 == null || u.profileImageBase64!.isEmpty)
                      ? Text(
                          u.fullName.isNotEmpty
                              ? (u.fullName.length >= 2 ? u.fullName.substring(0, 2).toUpperCase() : u.fullName.toUpperCase())
                              : (u.username.length >= 2 ? u.username.substring(0, 2).toUpperCase() : u.username.toUpperCase()),
                          style: GoogleFonts.outfit(color: themeColor, fontWeight: FontWeight.bold, fontSize: 14),
                        )
                      : null,
                ),
                const SizedBox(width: 20),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        u.fullName,
                        style: GoogleFonts.inter(color: state.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.badge_outlined, size: 14, color: state.textSecondaryLight),
                          const SizedBox(width: 4),
                          Text(
                            'Identifiant : ${u.username}',
                            style: GoogleFonts.inter(color: state.textSecondary, fontSize: 12.5),
                          ),
                          const SizedBox(width: 20),
                          Icon(Icons.email_outlined, size: 14, color: state.textSecondaryLight),
                          const SizedBox(width: 4),
                          Text(
                            'Email : ${u.email}',
                            style: GoogleFonts.inter(color: state.textSecondary, fontSize: 12.5),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // List of authorized permissions
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: u.permissions.map((p) {
                          String label = p;
                          switch (p) {
                            case 'dashboard':
                              label = 'Tableau de bord';
                              break;
                            case 'pos':
                              label = 'Point de Ventes (POS)';
                              break;
                            case 'add_product':
                              label = 'Ajouter un produit';
                              break;
                            case 'new_medicines':
                              label = 'Nouveaux médicaments';
                              break;
                            case 'reports':
                              label = 'Rapports des Ventes';
                              break;
                            case 'archives':
                              label = 'Archives Reçus';
                              break;
                            case 'loans':
                              label = 'Dettes';
                              break;
                            case 'replenish':
                              label = 'Réapprovisionnement';
                              break;
                            case 'suppliers':
                              label = 'Fournisseurs';
                              break;
                            case 'history':
                              label = 'Historique des Ventes';
                              break;
                          }
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: themeColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: themeColor.withOpacity(0.18)),
                            ),
                            child: Text(
                              label,
                              style: GoogleFonts.inter(
                                color: themeColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                // Actions
                IconButton(
                  icon: Icon(Icons.edit_outlined, color: state.textSecondary, size: 20),
                  tooltip: 'Modifier les informations & droits',
                  onPressed: () => _showAddUserDialog(context, state, u),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                  tooltip: 'Supprimer ce compte',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: state.bgSecondary,
                        title: Text('Supprimer le compte', style: GoogleFonts.outfit(color: state.textPrimary)),
                        content: Text(
                          'Êtes-vous sûr de vouloir supprimer le compte vendeur de ${u.fullName} ? Cette action est irréversible.',
                          style: GoogleFonts.inter(color: state.textSecondary),
                        ),
                        actions: [
                          TextButton(
                            child: Text('Annuler', style: TextStyle(color: state.textSecondaryLight)),
                            onPressed: () => Navigator.pop(context),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
                            onPressed: () {
                              state.deleteUser(u.username);
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // HELPERS & DIALOGS
  // ==========================================
  Widget _dialogField({
    required String label,
    required TextEditingController controller,
    bool required = false,
    bool readOnly = false,
    String? hintText,
  }) {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(color: state.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          enabled: !readOnly,
          style: GoogleFonts.inter(color: state.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: state.bgPrimary,
            hintText: hintText,
            hintStyle: GoogleFonts.inter(color: state.textSecondaryLight, fontSize: 12.5),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
          validator: (value) {
            if (required && (value == null || value.trim().isEmpty)) {
              return 'Ce champ est requis';
            }
            return null;
          },
        ),
      ],
    );
  }

  // Add / Edit User Dialog
  void _showAddUserDialog(BuildContext context, AppStateProvider state, [UserAccount? original]) {
    final isEdit = original != null;
    final formKey = GlobalKey<FormState>();
    final userCtrl = TextEditingController(text: isEdit ? original.username : '');
    final nameCtrl = TextEditingController(text: isEdit ? original.fullName : '');
    final emailCtrl = TextEditingController(text: isEdit ? original.email : '');
    final passCtrl = TextEditingController(text: isEdit ? original.password : '');

    // Default permissions for a new vendor
    List<String> selectedPermissions = isEdit
        ? List<String>.from(original.permissions)
        : ['dashboard', 'pos', 'archives'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: state.bgSecondary,
              title: Text(
                isEdit ? 'Modifier le Compte Vendeur' : 'Créer un nouveau Compte Vendeur',
                style: GoogleFonts.outfit(color: state.textPrimary),
              ),
              content: SizedBox(
                width: 480,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _dialogField(label: 'Identifiant / Nom d\'utilisateur', controller: userCtrl, required: true, readOnly: isEdit),
                        const SizedBox(height: 12),
                        _dialogField(label: 'Nom Complet du Vendeur', controller: nameCtrl, required: true),
                        const SizedBox(height: 12),
                        _dialogField(label: 'Email Professionnel', controller: emailCtrl, required: true),
                        const SizedBox(height: 12),
                        _dialogField(label: 'Mot de Passe', controller: passCtrl, required: true),
                        const SizedBox(height: 16),

                        Text(
                          'Autoriser l\'accès aux modules :',
                          style: GoogleFonts.inter(color: state.textSecondary, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 340,
                          decoration: BoxDecoration(
                            color: state.bgPrimary,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: state.borderTheme),
                          ),
                          child: RawScrollbar(
                            thumbColor: const Color(0xFF10B981).withOpacity(0.3),
                            radius: const Radius.circular(4),
                            thickness: 4,
                            child: ListView(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              children: [
                                _buildPermissionCheckbox('dashboard', 'Tableau de bord', selectedPermissions, setDialogState, state),
                                _buildPermissionCheckbox('pos', 'Point de ventes (POS)', selectedPermissions, setDialogState, state),
                                _buildPermissionCheckbox('add_product', 'Ajouter un produit', selectedPermissions, setDialogState, state),
                                _buildPermissionCheckbox('new_medicines', 'Nouveaux médicaments', selectedPermissions, setDialogState, state),
                                _buildPermissionCheckbox('reports', 'Rapport de ventes', selectedPermissions, setDialogState, state),
                                _buildPermissionCheckbox('archives', 'Archives réçu', selectedPermissions, setDialogState, state),
                                _buildPermissionCheckbox('loans', 'Dettes', selectedPermissions, setDialogState, state),
                                _buildPermissionCheckbox('replenish', 'Réapprovisionnement', selectedPermissions, setDialogState, state),
                                _buildPermissionCheckbox('suppliers', 'Fournisseurs', selectedPermissions, setDialogState, state),
                                _buildPermissionCheckbox('history', 'Historique des ventes', selectedPermissions, setDialogState, state),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  child: Text('Annuler', style: GoogleFonts.inter(color: state.textSecondaryLight)),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                  child: Text(
                    isEdit ? 'Modifier' : 'Créer le Compte',
                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      final newUser = UserAccount(
                        username: userCtrl.text.trim(),
                        fullName: nameCtrl.text.trim(),
                        email: emailCtrl.text.trim(),
                        password: passCtrl.text.trim(),
                        role: 'VENDEUR',
                        permissions: selectedPermissions,
                      );

                      if (isEdit) {
                        state.editUser(newUser);
                      } else {
                        state.addUser(newUser);
                      }
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPermissionCheckbox(
    String key,
    String label,
    List<String> selectedList,
    StateSetter setState,
    AppStateProvider state,
  ) {
    final isChecked = selectedList.contains(key);
    return CheckboxListTile(
      value: isChecked,
      title: Text(label, style: GoogleFonts.inter(color: state.textPrimary, fontSize: 13)),
      activeColor: const Color(0xFF10B981),
      checkColor: Colors.white,
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      onChanged: (val) {
        setState(() {
          if (val == true) {
            if (!selectedList.contains(key)) selectedList.add(key);
          } else {
            selectedList.remove(key);
          }
        });
      },
    );
  }
}
