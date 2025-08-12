import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fpt_final_project_mobile/admin/models/staff_profile_model.dart';
import 'package:fpt_final_project_mobile/admin/models/user_model.dart';
import 'package:fpt_final_project_mobile/admin/services/user_service.dart';
import 'package:image_picker/image_picker.dart';

class UserFormPage extends StatefulWidget {
  final UserService userService;
  final UserModel? initialUser; // null = tạo mới, không null = edit

  const UserFormPage({super.key, required this.userService, this.initialUser});

  @override
  _UserFormPageState createState() => _UserFormPageState();
}

class _UserFormPageState extends State<UserFormPage> {
  int _currentStep = 0;
  final _formKeys = List.generate(3, (_) => GlobalKey<FormState>());

  // Controllers cho các field
  late TextEditingController _usernameC;
  late TextEditingController _passwordC;
  late TextEditingController _confirmC;
  late TextEditingController _nameC;
  late TextEditingController _emailC;
  late TextEditingController _phoneC;
  late TextEditingController _positionC;
  late TextEditingController _addressC;
  late TextEditingController _dobC;
  late TextEditingController _workLocC;

  String _role = 'STAFF';
  String _gender = 'Male';

  File? _avatarFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final u = widget.initialUser;
    _usernameC = TextEditingController(text: u?.username ?? '');
    _passwordC = TextEditingController();
    _confirmC = TextEditingController();
    _nameC = TextEditingController(text: u?.name ?? '');
    _emailC = TextEditingController(text: u?.email ?? '');
    _phoneC = TextEditingController(text: u?.phone ?? '');
    _positionC = TextEditingController(text: u?.staffProfile?.position ?? '');
    _addressC = TextEditingController(text: u?.staffProfile?.address ?? '');
    _dobC = TextEditingController(text: u?.staffProfile?.dob ?? '');
    _workLocC = TextEditingController(
      text: u?.staffProfile?.workLocation ?? '',
    );
    _role = u?.role ?? 'STAFF';
    _gender = u?.staffProfile?.gender ?? 'Male';
    if (u?.imageUrl != null) {
      // TODO: fetch network image into File? hoặc giữ preview URL
    }
  }

  @override
  void dispose() {
    for (var c in [
      _usernameC,
      _passwordC,
      _confirmC,
      _nameC,
      _emailC,
      _phoneC,
      _positionC,
      _addressC,
      _dobC,
      _workLocC,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final XFile? img = await _picker.pickImage(source: ImageSource.gallery);
    if (img != null) setState(() => _avatarFile = File(img.path));
  }

  // Validation helpers
  String? _validateNotEmpty(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Cant be not null' : null;

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email required';
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)
        ? null
        : 'Email is not right';
  }

  String? _validatePhone(String? v) =>
      (v == null || !RegExp(r'^\d{10}$').hasMatch(v)) ? '10 numbers' : null;

  String? _validatePassword(String? v) {
    if (widget.initialUser != null && (v == null || v.isEmpty)) return null;
    if (v == null || v.length < 6) return '≥6 charecters';
    if (!RegExp(r'(?=.*[0-9])').hasMatch(v)) return 'Need numbers';
    if (!RegExp(r'(?=.*[A-Za-z])').hasMatch(v)) return 'Need characters';
    return null;
  }

  String? _validateConfirm(String? v) {
    if (_validatePassword(_passwordC.text) != null) return null;
    return v != _passwordC.text ? 'It is not correct!!!' : null;
  }

  bool _stepValid(int idx) {
    return _formKeys[idx].currentState?.validate() ?? false;
  }

  Future<void> _onSubmit() async {
    // build UserModel
    final user = UserModel(
      id: widget.initialUser?.id ?? '',
      username: _usernameC.text.trim(),
      name: _nameC.text.trim(),
      email: _emailC.text.trim(),
      phone: _phoneC.text.trim(),
      role: _role,
      imageUrl: widget.initialUser?.imageUrl,
      staffProfile: _role == 'STAFF'
          ? StaffProfileModel(
              position: _positionC.text.trim(),
              shiftType: _positionC.text
                  .trim(), // sửa lại nếu cần riêng shiftType
              address: _addressC.text.trim(),
              dob: _dobC.text.trim(),
              gender: _gender,
              workLocation: _workLocC.text.trim(),
            )
          : null,
    );
    try {
      if (widget.initialUser == null) {
        await widget.userService.createUser(user, password: _passwordC.text);
      } else {
        await widget.userService.updateUser(
          user,
          newPassword: _passwordC.text.isNotEmpty ? _passwordC.text : null,
        );
      }
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialUser != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit User' : 'Register User')),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 2) {
            if (_stepValid(_currentStep)) {
              setState(() => _currentStep++);
            }
          } else {
            // submit khi step cuối
            if (_stepValid(0) && _stepValid(1) && _stepValid(2)) {
              _onSubmit();
            }
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) setState(() => _currentStep--);
        },
        steps: [
          // STEP 1: ACCOUNT
          Step(
            title: Text('Account'),
            isActive: _currentStep >= 0,
            content: Form(
              key: _formKeys[0],
              child: Column(
                children: [
                  TextFormField(
                    controller: _usernameC,
                    decoration: InputDecoration(labelText: 'Username'),
                    validator: _validateNotEmpty,
                    enabled: !isEdit,
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordC,
                    decoration: InputDecoration(
                      labelText: isEdit ? 'New Password (opt)' : 'Password',
                    ),
                    obscureText: true,
                    validator: _validatePassword,
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: _confirmC,
                    decoration: InputDecoration(labelText: 'Confirm Password'),
                    obscureText: true,
                    validator: _validateConfirm,
                  ),
                ],
              ),
            ),
          ),

          // STEP 2: PERSONAL
          Step(
            title: Text('Personal'),
            isActive: _currentStep >= 1,
            content: Form(
              key: _formKeys[1],
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameC,
                    decoration: InputDecoration(labelText: 'Full Name'),
                    validator: _validateNotEmpty,
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: _emailC,
                    decoration: InputDecoration(labelText: 'Email'),
                    validator: _validateEmail,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: _phoneC,
                    decoration: InputDecoration(labelText: 'Phone'),
                    validator: _validatePhone,
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
          ),

          // STEP 3: ROLE & DETAILS
          Step(
            title: Text('Role & Details'),
            isActive: _currentStep >= 2,
            content: Form(
              key: _formKeys[2],
              child: Column(
                children: [
                  // Role dropdown
                  DropdownButtonFormField<String>(
                    value: _role,
                    items: ['ADMIN', 'STAFF', 'SHIPPER']
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (v) => setState(() => _role = v!),
                    decoration: InputDecoration(labelText: 'Role'),
                  ),

                  if (_role == 'STAFF') ...[
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _positionC,
                      decoration: InputDecoration(labelText: 'Position'),
                      validator: _role == 'STAFF' ? _validateNotEmpty : null,
                    ),
                    SizedBox(height: 8),
                    // bạn có thể thêm ShiftType giống Position
                    TextFormField(
                      controller: _addressC,
                      decoration: InputDecoration(labelText: 'Address'),
                      validator: _validateNotEmpty,
                    ),
                    SizedBox(height: 8),
                    // DOB picker
                    TextFormField(
                      controller: _dobC,
                      decoration: InputDecoration(labelText: 'Date of Birth'),
                      onTap: () async {
                        DateTime? d = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (d != null) {
                          _dobC.text = d.toIso8601String().split('T').first;
                        }
                      },
                      readOnly: true,
                      validator: _validateNotEmpty,
                    ),
                    SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _gender,
                      items: ['Male', 'Female', 'Other']
                          .map(
                            (g) => DropdownMenuItem(value: g, child: Text(g)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _gender = v!),
                      decoration: InputDecoration(labelText: 'Gender'),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _workLocC,
                      decoration: InputDecoration(labelText: 'Work Location'),
                      validator: _validateNotEmpty,
                    ),
                  ],

                  SizedBox(height: 12),
                  // Avatar picker
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickAvatar,
                        icon: Icon(Icons.image),
                        label: Text('Pick Avatar'),
                      ),
                      SizedBox(width: 12),
                      if (_avatarFile != null)
                        Image.file(_avatarFile!, width: 50, height: 50),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
