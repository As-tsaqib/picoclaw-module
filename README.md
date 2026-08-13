# PicoClaw Module

Modul root Android ARM64 untuk [PicoClaw](https://github.com/sipeed/picoclaw),
ditujukan terutama untuk **KernelSU Next** dan tetap mengikuti format modul
Magisk/KSU yang umum. Binary CLI dan launcher web dibangun dari fork kustom
`As-tsaqib/picoclaw` yang memuat release stabil upstream terbaru serta
perubahan integrasi Telegram.

## Fitur

- Build terikat pada commit fork yang dapat diaudit dan diverifikasi memuat
  commit tag release resmi `sipeed/picoclaw`.
- Metadata `build-info.prop` di dalam ZIP mencatat tag upstream, commit
  upstream, commit fork, dan repository source kustom.
- Pemeriksaan upstream otomatis sekali sehari pada pukul **00:00 UTC**
  (08:00 WITA), sesuai jadwal workflow release.
- Release ZIP modul dibuat otomatis hanya ketika versi upstream atau revisi
  modul berubah.
- `picoclaw` dan `picoclaw-launcher` Android ARM64 dibangun dari source,
  termasuk frontend dashboard resmi yang di-embed ke launcher.
- Pada Android, binary memakai resolver Go dengan fallback DNS ketika
  `/etc/resolv.conf` tidak tersedia. Server DNS dapat diatur melalui
  `PICOCLAW_DNS_SERVER` (format `host:port;host:port`); tanpa pengaturan ini
  upstream memakai fallback publik `8.8.8.8:53;1.1.1.1:53`.
- Patch kompatibilitas yang dilacak di repo mempertahankan mode launcher
  headless Android ketika cgo aktif; patch dilewati otomatis apabila struktur
  upstream sudah berubah.
- WebUI KSU Next untuk start/stop/restart launcher, autostart, status, log, dan
  pemasangan ulang wrapper Termux.
- Launcher web berjalan otomatis di `http://127.0.0.1:18800` dan tidak diekspos
  ke jaringan lokal secara default.
- Bersifat mountless (`skip_mount`): tidak memodifikasi `/system` dan tidak
  memerlukan metamodule OverlayFS di KSU Next.
- Data persisten disimpan di `/data/adb/picoclaw`, sehingga tidak hilang saat
  modul diperbarui.
- Wrapper berikut dapat dipanggil langsung dari Termux tanpa mengetik `su`:
  `picoclaw`, `picoclaw-config`, `picoclaw-onboard`, `picoclaw-agent`,
  `picoclaw-auth`, `picoclaw-gateway`, `picoclaw-status`, `picoclaw-cron`,
  `picoclaw-mcp`, `picoclaw-migrate`, `picoclaw-skills`, `picoclaw-model`,
  `picoclaw-update`, `picoclaw-version`, `picoclaw-launcher`, `picoclaw-web`,
  dan `picoclaw-ctl`.

## Instalasi

1. Pastikan perangkat menggunakan ARM64 dan KSU Next sudah aktif.
2. Pasang Termux lebih dahulu agar wrapper dapat dibuat saat instalasi modul.
3. Unduh ZIP dari halaman [Releases](https://github.com/As-tsaqib/picoclaw-module/releases).
4. Pasang ZIP melalui KSU Next Manager, lalu reboot.
5. Buka Termux dan jalankan `picoclaw version`. Berikan izin superuser kepada
   Termux satu kali ketika diminta KSU Next.
6. Jalankan `picoclaw onboard`, atau buka WebUI modul lalu tekan **Buka
   dashboard**. Pada akses pertama, buat password dashboard di halaman
   `/launcher-setup`.

Jika Termux dipasang setelah modul, tekan tombol **Action** atau tombol
**Pasang wrapper Termux** di WebUI modul.

Wrapper memang memanggil `su` secara internal karena `/data/adb/modules` tidak
dapat diakses UID aplikasi Android. Argumen CLI diteruskan dengan quoting dan
exit code asli dipertahankan; pengguna tidak perlu membuka shell root terlebih
dahulu. Semua proses PicoClaw dari wrapper berjalan sebagai root dan memakai
state yang sama dengan service dashboard.

## Perintah singkat

```sh
picoclaw version
picoclaw onboard
picoclaw-agent "Halo"
picoclaw-status
picoclaw-gateway
picoclaw-ctl status
picoclaw-ctl port 18801
picoclaw-ctl backup
picoclaw-ctl restore /sdcard/Download/picoclaw-backup-20260810_220000.tar.gz
picoclaw-ctl restart
picoclaw-web -port 18801
```

Alias `picoclaw-<subcommand>` sama dengan `picoclaw <subcommand>`. Perintah
`picoclaw-web` menjalankan launcher dalam mode console/no-browser, sedangkan
`picoclaw-launcher` mempertahankan perilaku launcher upstream.

Gunakan update modul dari KSU Next untuk memperbarui instalasi. Perintah
upstream `picoclaw update` hanya memperbarui satu binary dan tidak memperbarui
launcher maupun metadata modul, sehingga tidak disarankan untuk instalasi ini.

## Lokasi penting

| Lokasi | Isi |
| --- | --- |
| `/data/adb/modules/picoclaw/bin` | Binary yang dikelola modul |
| `/data/adb/picoclaw/config.json` | Konfigurasi PicoClaw |
| `/data/adb/picoclaw/workspace` | Workspace default |
| `/data/adb/picoclaw/settings.conf` | Autostart, host, dan port launcher |
| `/data/adb/picoclaw/logs/launcher-module.log` | Log service launcher |
| `$PREFIX/bin/picoclaw*` | Wrapper kecil saja, bukan binary PicoClaw |

Backup/restore mengelola config, settings, workspace, credential PicoClaw,
credential OAuth, konfigurasi/password dashboard, dan key SSH internal.
PID, lock, log, serta file temporary tidak dipulihkan. Archive restore hanya
menerima entry allowlist tanpa traversal atau symlink dan memakai rollback jika
commit atau start ulang launcher gagal.
Archive backup tidak dienkripsi; simpan dengan izin terbatas dan enkripsi
sebelum menyalinnya ke lokasi atau perangkat lain.

Data persisten sengaja tidak dihapus ketika modul di-uninstall. Hapus manual
`/data/adb/picoclaw` hanya jika Anda memang ingin menghapus config, credential,
workspace, dan log.

## Otomasi release

Workflow `Sync upstream release` melakukan alur berikut:

1. meminta release stabil terbaru dari GitHub API;
2. membandingkannya dengan `UPSTREAM_VERSION`, revisi modul, dan commit fork;
3. checkout commit fork kustom dan memverifikasi tag upstream merupakan
   ancestor-nya;
4. memakai versi Go dari `go.mod`, menerapkan patch kompatibilitas Android yang
   diperlukan, membangun frontend dengan lockfile pnpm, lalu menjalankan target
   Android resmi upstream;
5. memvalidasi kedua ELF ARM64, merakit ZIP modul, dan membuat checksum;
6. menerbitkan GitHub Release serta memperbarui `update.json`.

Workflow pada fork PicoClaw (`As-tsaqib/picoclaw`) berjalan lebih dahulu setiap
hari untuk menggabungkan release stabil terbaru dari `sipeed/picoclaw` ke branch
kustom. Jika terjadi konflik, workflow berhenti agar perubahan tidak dibangun
secara diam-diam. Workflow module memeriksa source fork pada jadwalnya sendiri
dan memverifikasi commit tersebut sebelum build.

Workflow juga dapat dijalankan manual dari tab Actions. Naikkan angka dalam
`MODULE_REVISION` bila kode modul berubah dan release untuk versi upstream yang
sama perlu dibuat ulang.

## Build lokal

Dependensi: Bash, Go sesuai `upstream/go.mod`, Node.js, npm/pnpm, `make`, `zip`,
`file`, serta compiler ARM64 dari Android NDK. Di Termux compiler
`aarch64-linux-android-clang` dideteksi otomatis. Pada host Linux lain, arahkan
`PICOCLAW_ANDROID_CC` ke compiler NDK dan pilih API minimum dengan
`PICOCLAW_ANDROID_API` (default 21).

```sh
git clone https://github.com/As-tsaqib/picoclaw.git upstream
git -C upstream checkout main
PICOCLAW_ANDROID_CC="$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android21-clang" \
  make build SOURCE_DIR="$PWD/upstream" UPSTREAM_TAG=v0.3.1
```

Artefak berada di `dist/`. Jalankan `make test` untuk pemeriksaan statis,
tes perakitan ZIP, dan regression test backup/restore. Jalankan
`make webui-check` untuk membangun frontend dari `webui/package-lock.json` dan
memastikan `module/webroot/` sinkron. Build upstream menggunakan Git worktree
sementara sehingga source checkout tetap bersih setelah patch Android dan
kompilasi selesai.

## Lisensi

Kode modul menggunakan lisensi MIT. PicoClaw juga berlisensi MIT; lisensi
upstream selalu disertakan di dalam ZIP. Lihat [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
