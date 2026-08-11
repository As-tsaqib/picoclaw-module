# PicoClaw Module v0.3.1-r7

Berbasis release upstream `v0.3.1`, dibangun dari fork kustom `5f9087b0976d0da82e5b26ecf90032513e70ab61`.

## Pembaruan & Fitur Utama

- **WebUI Redesign & Theme Switcher**:
  - Tombol pengalih Mode Terang (Light) / Mode Gelap (Dark) di header kanan atas (tersimpan otomatis di LocalStorage).
  - Logo maskot lobster resmi PicoClaw transparan di header kiri atas.
  - Efek tekan *spring physics*, gelombang *ripple wave*, dan getaran *haptic feedback* (10ms) pada setiap tombol.

- **Pembersihan Log Service**:
  - Menghapus kolom nomor baris di viewer log.
  - Pembersihan otomatis kode warna ANSI mentah (`[38;2;...m`) dan pecahan banner ASCII.
  - Penambahan `NO_COLOR=1` & `TERM=dumb` pada launcher service.

- **Integrasi Upstream & Fork**:
  - Menyertakan 7 commit terbaru dari fork `As-tsaqib/picoclaw` (fitur contextual memory dan safe evolution controls).
  - Binary `picoclaw` dan `picoclaw-launcher` ARM64 dibangun dari source dengan Android NDK.

---

### Cara Pasang / Perbarui
1. Tekan tombol **Update** di KernelSU Next Manager.
2. Lakukan **Reboot** perangkat setelah proses flashing selesai.
