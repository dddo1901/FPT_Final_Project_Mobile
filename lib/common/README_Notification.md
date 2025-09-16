# Flutter Notification System

Hệ thống notification cho Flutter app được thiết kế dựa theo React NotificationContext, cung cấp các tính năng:

## Tính năng

### 1. Notification Types
- **Success**: Thông báo thành công (màu xanh lá)
- **Error**: Thông báo lỗi (màu đỏ) 
- **Warning**: Thông báo cảnh báo (màu cam)
- **Info**: Thông báo thông tin (màu xanh dương)

### 2. Notification Icon với Badge
- Icon notification trong AppBar với badge counter
- Hiển thị số lượng notification chưa đọc
- Mở panel notification khi tap

### 3. Notification Panel
- Bottom sheet hiển thị lịch sử notification
- Mark as read individual hoặc all
- Clear all notifications
- Responsive design với scroll

### 4. Confirm Dialog
- Dialog xác nhận với tùy chọn Yes/No
- Tùy chỉnh màu sắc và text
- Trả về Promise<bool>

### 5. Auto Close & History
- Notification tự động đóng sau thời gian xác định
- Error notification mặc định không tự đóng
- Lưu trữ history và trạng thái đã đọc/chưa đọc
- Animation slide + fade mượt mà

## Cách sử dụng

### 1. Setup trong main.dart

```dart
// Đã được setup sẵn trong MultiProvider
ChangeNotifierProvider(
  create: (_) => NotificationProvider(),
),

// Trong MaterialApp builder
builder: (context, child) {
  return NotificationOverlay(child: child ?? const SizedBox.shrink());
},
```

### 2. Import Extension & Widgets

```dart
import '../../common/extensions/notification_extension.dart';
import '../../common/widgets/notification_icon.dart';
```

### 3. Thêm Notification Icon vào AppBar

```dart
AppBar(
  title: const Text('My Page'),
  actions: const [
    NotificationIcon(), // Thêm icon với badge counter
  ],
)
```

### 4. Sử dụng Notifications

#### Success Notification
```dart
context.showSuccess('Data saved successfully!');

// Với tùy chọn
context.showSuccess(
  'User created successfully',
  title: 'Success',
  autoClose: true,
  duration: const Duration(seconds: 5),
);
```

#### Error Notification  
```dart
context.showError('Failed to load data');

// Error mặc định không tự đóng
context.showError(
  'Network connection failed',
  title: 'Connection Error',
  autoClose: false,
);
```

#### Warning Notification
```dart
context.showWarning('Password will expire in 3 days');
```

#### Info Notification
```dart
context.showInfo('New version available');
```

#### Confirm Dialog
```dart
final result = await context.showConfirm(
  title: 'Delete Item',
  message: 'Are you sure you want to delete this item?',
  confirmText: 'Delete',
  cancelText: 'Cancel',
  confirmColor: Colors.red,
);

if (result) {
  // User confirmed
  deleteItem();
} else {
  // User cancelled
}
```

#### Notification Management
```dart
// Mark as read
context.markNotificationAsRead(notificationId);

// Mark all as read
context.markAllNotificationsAsRead();

// Get unread count
int unreadCount = context.unreadNotificationCount;

// Clear all notifications
context.clearNotifications();
```

## Components

### NotificationIcon Widget

```dart
const NotificationIcon(
  iconColor: Colors.white, // Tùy chọn màu icon
  iconSize: 24.0,         // Tùy chọn kích thước
)
```

### NotificationPanel

- **Auto-open**: Khi tap vào NotificationIcon
- **Drag handle**: Kéo để đóng
- **Mark all read**: Button trong header
- **Clear all**: Icon button với confirm dialog
- **Individual items**: Tap để mark as read

### NotificationData Properties

```dart
NotificationData(
  id: String,           // Unique identifier
  type: NotificationType, // success, error, warning, info
  title: String,        // Notification title
  message: String,      // Notification message
  priority: NotificationPriority, // low, medium, high
  autoClose: bool,      // Auto dismiss
  duration: Duration,   // How long to show
  timestamp: DateTime,  // When created
  isRead: bool,         // Read status
  onTap: VoidCallback?, // Tap handler
  onDismiss: VoidCallback?, // Dismiss handler
)
```

## Ví dụ thực tế

### Trong API Calls
```dart
try {
  final data = await apiService.getData();
  context.showSuccess('Data loaded successfully');
} catch (e) {
  context.showError('Failed to load data: $e');
}
```

### Trong Form Submission
```dart
Future<void> submitForm() async {
  try {
    await apiService.submitData(formData);
    context.showSuccess('Form submitted successfully');
    Navigator.pop(context);
  } catch (e) {
    context.showError('Failed to submit form: $e');
  }
}
```

### Confirm trước khi xóa
```dart
Future<void> deleteItem(String id) async {
  final confirmed = await context.showConfirm(
    title: 'Delete Item',
    message: 'This action cannot be undone',
    confirmText: 'Delete',
    confirmColor: Colors.red,
  );
  
  if (confirmed) {
    try {
      await apiService.deleteItem(id);
      context.showSuccess('Item deleted successfully');
    } catch (e) {
      context.showError('Failed to delete item: $e');
    }
  }
}
```

## Routes

- `/notification-demo` - Trang demo notification system

## Demo & Testing

1. **Notification Demo Page**: 
   - Access via `/notification-demo` route
   - Test tất cả loại notifications
   - Test confirm dialog
   - Test notification icon với badge

2. **Real Usage**:
   - StaffRequestListPage đã tích hợp notifications
   - RequestCreatePage đã tích hợp notifications
   - Admin & Staff có thể test thực tế

## Badge Counter Features

- **Real-time update**: Badge số thay đổi theo số notification chưa đọc
- **99+ display**: Hiển thị "99+" nếu có hơn 99 notifications
- **Auto hide**: Badge ẩn khi không có notification chưa đọc
- **Visual indicator**: Màu đỏ nổi bật với shadow

## Tùy chỉnh

### Thay đổi màu sắc
Chỉnh sửa trong `notification_data.dart`:

```dart
Color get backgroundColor {
  switch (type) {
    case NotificationType.success:
      return Colors.green[600]!; // Thay đổi màu ở đây
    // ...
  }
}
```

### Thay đổi thời gian mặc định
Chỉnh sửa trong `notification_provider.dart`:

```dart
String showSuccess(String message, {
  Duration duration = const Duration(seconds: 5), // Thay đổi ở đây
  // ...
})
```

### Tùy chỉnh Notification Icon
```dart
NotificationIcon(
  iconColor: Colors.blue,    // Màu icon
  iconSize: 28.0,           // Kích thước icon
)
```

## Lưu ý

1. **Error notification** mặc định không tự đóng để đảm bảo user thấy được lỗi
2. **Notification history** được lưu trữ và có thể xem lại
3. **Badge counter** cập nhật real-time theo số notification chưa đọc
4. **Panel responsive** với drag-to-dismiss và scroll
5. **Animation mượt mà** với slide + fade effect
6. **Auto mark as read** khi user tap vào notification trong panel
7. **Persistent storage** - có thể mở rộng để lưu vào local storage

## Files Structure

```
lib/common/
├── models/
│   └── notification_data.dart
├── providers/
│   └── notification_provider.dart
├── widgets/
│   ├── notification_widget.dart
│   ├── notification_overlay.dart
│   ├── notification_icon.dart
│   └── notification_panel.dart
├── extensions/
│   └── notification_extension.dart
└── README_Notification.md
```