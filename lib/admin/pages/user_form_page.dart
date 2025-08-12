import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:fpt_final_project_mobile/admin/models/staff_profile_model.dart';
import 'package:fpt_final_project_mobile/admin/models/user_model.dart';
import 'package:fpt_final_project_mobile/admin/services/user_service.dart';

class UserFormPage extends StatefulWidget {
  final UserService userService;
  final UserModel? initialUser; // null = tạo mới, != null = edit

  const UserFormPage({super.key, required this.userService, this.initialUser});

  @override
  State<UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends State<UserFormPage> {
  int _currentStep = 0;
  final _formKeys = List.generate(3, (_) => GlobalKey<FormState>());

  // controllers
  late final TextEditingController _usernameC;
  late final TextEditingController _passwordC;
  late final TextEditingController _confirmC;
  late final TextEditingController _nameC;
  late final TextEditingController _emailC;
  late final TextEditingController _phoneC;

  late final TextEditingController _positionC;
  late final TextEditingController _shiftTypeC;
  late final TextEditingController _addressC;
  late final TextEditingController _dobC;
  late final TextEditingController _workLocC;

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
    _shiftTypeC = TextEditingController(text: u?.staffProfile?.shiftType ?? '');
    _addressC = TextEditingController(text: u?.staffProfile?.address ?? '');
    _dobC = TextEditingController(text: u?.staffProfile?.dob ?? '');
    _workLocC = TextEditingController(
      text: u?.staffProfile?.workLocation ?? '',
    );

    _role = u?.role ?? 'STAFF';
    _gender = u?.staffProfile?.gender ?? 'Male';

    // Nếu muốn preview ảnh từ URL, bạn có thể hiển thị qua Image.network(u.imageUrl) ở UI,
    // còn việc “download về File” thì thường không cần cho form này.
  }

  @override
  void dispose() {
    for (final c in [
      _usernameC,
      _passwordC,
      _confirmC,
      _nameC,
      _emailC,
      _phoneC,
      _positionC,
      _shiftTypeC,
      _addressC,
      _dobC,
      _workLocC,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // pick avatar
  Future<void> _pickAvatar() async {
    final XFile? img = await _picker.pickImage(source: ImageSource.gallery);
    if (img != null) setState(() => _avatarFile = File(img.path));
  }

  // ===== Validators =====
  String? _notEmpty(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Không được để trống' : null;

  String? _email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email bắt buộc';
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)
        ? null
        : 'Email không hợp lệ';
  }

  String? _phone(String? v) => (v == null || !RegExp(r'^\d{10}$').hasMatch(v))
      ? 'Số điện thoại 10 số'
      : null;

  String? _password(String? v) {
    // Edit: cho phép bỏ qua nếu không đổi pass
    if (widget.initialUser != null && (v == null || v.isEmpty)) return null;
    if (v == null || v.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
    if (!RegExp(r'(?=.*[0-9])').hasMatch(v)) return 'Cần ít nhất 1 chữ số';
    if (!RegExp(r'(?=.*[A-Za-z])').hasMatch(v)) return 'Cần ít nhất 1 chữ cái';
    return null;
  }

  String? _confirm(String? v) {
    // Chỉ check khi password hợp lệ hoặc đang tạo mới
    final pwErr = _password(_passwordC.text);
    if (pwErr == null && v != _passwordC.text)
      return 'Xác nhận mật khẩu không khớp';
    return null;
  }

  bool _validateStep(int idx) =>
      _formKeys[idx].currentState?.validate() ?? false;

  // ===== Submit =====
  Future<void> _onSubmit() async {
    final user = UserModel(
      id: widget.initialUser?.id ?? '',
      username: _usernameC.text.trim(),
      name: _nameC.text.trim(),
      email: _emailC.text.trim(),
      phone: _phoneC.text.trim(),
      role: _role,
      imageUrl:
          widget.initialUser?.imageUrl, // giữ nguyên nếu edit mà không đổi ảnh
      staffProfile: _role == 'STAFF'
          ? StaffProfileModel(
              position: _positionC.text.trim(),
              shiftType: _shiftTypeC.text.trim(),
              address: _addressC.text.trim(),
              dob: _dobC.text.trim(),
              gender: _gender,
              workLocation: _workLocC.text.trim(),
            )
          : null,
    );

    try {
      if (widget.initialUser == null) {
        // Create
        await widget.userService.createUser(
          user,
          password: _passwordC.text.trim(),
          imageFile: _avatarFile,
        );
      } else {
        // Update (theo service bạn đã dùng trước đó)
        await widget.userService.updateUser(
          user.id,
          user,
          imageFile: _avatarFile,
        );
        // Nếu backend có API đổi password riêng, bạn có thể gọi thêm ở đây khi _passwordC có giá trị.
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  // ===== UI =====
  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialUser != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit User' : 'Register User')),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 2) {
            if (_validateStep(_currentStep)) {
              setState(() => _currentStep++);
            }
          } else {
            // submit ở step cuối
            if (_validateStep(0) && _validateStep(1) && _validateStep(2)) {
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
            title: const Text('Account'),
            isActive: _currentStep >= 0,
            content: Form(
              key: _formKeys[0],
              child: Column(
                children: [
                  TextFormField(
                    controller: _usernameC,
                    decoration: const InputDecoration(labelText: 'Username'),
                    validator: _notEmpty,
                    enabled: !isEdit,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordC,
                    decoration: InputDecoration(
                      labelText: isEdit
                          ? 'New Password (optional)'
                          : 'Password',
                    ),
                    obscureText: true,
                    validator: _password,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _confirmC,
                    decoration: const InputDecoration(
                      labelText: 'Confirm Password',
                    ),
                    obscureText: true,
                    validator: _confirm,
                  ),
                ],
              ),
            ),
          ),

          // STEP 2: PERSONAL
          Step(
            title: const Text('Personal'),
            isActive: _currentStep >= 1,
            content: Form(
              key: _formKeys[1],
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameC,
                    decoration: const InputDecoration(labelText: 'Full Name'),
                    validator: _notEmpty,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailC,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: _email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _phoneC,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    validator: _phone,
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
          ),

          // STEP 3: ROLE & DETAILS
          Step(
            title: const Text('Role & Details'),
            isActive: _currentStep >= 2,
            content: Form(
              key: _formKeys[2],
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _role,
                    items: const [
                      DropdownMenuItem(value: 'ADMIN', child: Text('ADMIN')),
                      DropdownMenuItem(value: 'STAFF', child: Text('STAFF')),
                      DropdownMenuItem(
                        value: 'SHIPPER',
                        child: Text('SHIPPER'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _role = v ?? 'STAFF'),
                    decoration: const InputDecoration(labelText: 'Role'),
                  ),

                  if (_role == 'STAFF') ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _positionC,
                      decoration: const InputDecoration(labelText: 'Position'),
                      validator: _notEmpty,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _shiftTypeC,
                      decoration: const InputDecoration(
                        labelText: 'Shift Type',
                      ),
                      validator: _notEmpty,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _addressC,
                      decoration: const InputDecoration(labelText: 'Address'),
                      validator: _notEmpty,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _dobC,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Date of Birth',
                      ),
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (d != null) {
                          _dobC.text = d.toIso8601String().split('T').first;
                        }
                      },
                      validator: _notEmpty,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _gender,
                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(
                          value: 'Female',
                          child: Text('Female'),
                        ),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (v) => setState(() => _gender = v ?? 'Male'),
                      decoration: const InputDecoration(labelText: 'Gender'),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _workLocC,
                      decoration: const InputDecoration(
                        labelText: 'Work Location',
                      ),
                      validator: _notEmpty,
                    ),
                  ],

                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickAvatar,
                        icon: const Icon(Icons.image),
                        label: const Text('Pick Avatar'),
                      ),
                      const SizedBox(width: 12),
                      if (_avatarFile != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _avatarFile!,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          ),
                        ),
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
