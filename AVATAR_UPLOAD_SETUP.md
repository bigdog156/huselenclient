# Avatar Upload Feature - Setup Guide

## ✅ Đã hoàn thành:

### 1. **ImagePicker.swift**
   - Component cho phép user chọn ảnh từ thư viện
   - Sử dụng PHPickerViewController (iOS 14+)
   - Tự động convert ảnh thành UIImage

### 2. **ProfileViewModel.swift**
   - Thêm `isUploadingAvatar` state
   - Function `uploadAvatar(userId:image:)`:
     - Nén ảnh (JPEG quality 0.7)
     - Upload lên Supabase Storage
     - Cập nhật avatar_url trong database
     - Tự động reload profile

### 3. **ProfileView.swift**
   - Avatar có overlay button camera
   - Loading animation khi đang upload
   - Alert thông báo khi upload thành công
   - Tự động upload khi user chọn ảnh

## 🔧 Cấu hình Supabase Storage:

### Bước 1: Tạo Storage Bucket
1. Vào Supabase Dashboard → Storage
2. Tạo bucket mới tên: `user-avatars`
3. Set **Public bucket** = `true` (để có thể lấy public URL)

### Bước 2: Cấu hình Storage Policies
Chạy SQL này trong Supabase SQL Editor:

```sql
-- Policy cho phép user upload avatar của chính họ
CREATE POLICY "Users can upload their own avatar"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'user-avatars' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy cho phép user update avatar của chính họ
CREATE POLICY "Users can update their own avatar"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'user-avatars' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy cho phép mọi người xem avatar (public read)
CREATE POLICY "Anyone can view avatars"
ON storage.objects FOR SELECT
USING (bucket_id = 'user-avatars');

-- Policy cho phép user xóa avatar của chính họ
CREATE POLICY "Users can delete their own avatar"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'user-avatars' AND
  auth.uid()::text = (storage.foldername(name))[1]
);
```

### Bước 3: Kiểm tra Info.plist
Thêm permission cho Photo Library:
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Chúng tôi cần truy cập thư viện ảnh để bạn có thể chọn ảnh đại diện</string>
```

## 🎨 Tính năng:

- ✅ Click vào icon camera trên avatar để chọn ảnh
- ✅ Ảnh tự động nén trước khi upload (tiết kiệm storage)
- ✅ Loading animation trong khi upload
- ✅ Alert thông báo thành công/thất bại
- ✅ Avatar tự động refresh sau khi upload
- ✅ Support async/await (modern Swift)
- ✅ Error handling đầy đủ

## 📱 Cách sử dụng:

1. Vào màn hình Profile
2. Click vào icon camera màu xanh ở góc dưới avatar
3. Chọn ảnh từ thư viện
4. Đợi upload hoàn tất
5. Avatar sẽ tự động cập nhật!

## 🔍 Debugging:

Nếu gặp lỗi, check console log:
- "Error uploading avatar: ..." - Lỗi từ Supabase
- "Không thể nén ảnh" - Ảnh không hợp lệ

Common issues:
- ❌ Bucket chưa tạo hoặc không public
- ❌ Storage policies chưa setup đúng
- ❌ Info.plist chưa có permission
- ❌ Supabase client chưa authenticated
