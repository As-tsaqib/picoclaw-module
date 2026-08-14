# PicoClaw Module

Modul root Android ARM64 untuk PicoClaw, ditujukan terutama untuk **KernelSU
Next** dan tetap mengikuti format modul Magisk/KSU yang umum. Binary CLI dan
launcher web selalu dibangun dari repository fork resmi modul ini:
[`As-tsaqib/picoclaw`](https://github.com/As-tsaqib/picoclaw). Checkout atau
release dari repository lain tidak diperlukan.

## Fitur

- Build selalu terikat pada commit fork yang dapat diaudit. Script packing
  menolak source tree yang tidak memiliki remote `As-tsaqib/picoclaw`.
- Metadata `build-info.prop` di dalam ZIP mencatat repository, ref, commit,
  versi binary, dan versi module secara terpisah.
- Pemeriksaan commit fork otomatis sekali sehari pada pukul **00:00 UTC**
  (08:00 WITA), sesuai jadwal workflow release.
- Versi module mengikuti SemVer independen dan dimulai dari **1.0.0**. Versi
  binary PicoClaw tidak digunakan sebagai versi module.
- Release ZIP modul dibuat otomatis ketika commit fork atau versi module
  berubah.
- `picoclaw` dan `picoclaw-launcher` Android ARM64 dibangun dari source,
  termasuk frontend dashboard resmi yang di-embed ke launcher.
- Pada Android, binary memakai resolver Go dengan fallback DNS ketika
  `/etc/resolv.conf` tidak tersedia. Server DNS dapat diatur melalui
  `PICOCLAW_DNS_SERVER` (format `host:port;host:port`); tanpa pengaturan ini
  build Android memakai fallback publik `8.8.8.8:53;1.1.1.1:53`.
- Patch kompatibilitas yang dilacak di repo mempertahankan mode launcher
  headless Android ketika cgo aktif; patch dilewati otomatis apabila struktur
  source fork sudah berubah.
- WebUI KSU Next untuk start/stop/restart launcher, autostart, status, log, dan
  pemasangan ulang wrapper Termux.
- Kartu **Health & Diagnostics** menampilkan status HTTP, PID, uptime, waktu
  start, watchdog, pemeriksaan binary/permission/config/listener/wrapper, serta
  dapat menyalin laporan whitelist yang tidak berisi credential.
- **Service Logs** mendukung filter error/warning/info, pause/live tail, nomor
  baris, timestamp, export, wrap/raw mode, konfirmasi clear, dan redaksi
  token/password/secret di backend maupun WebUI.
- Launcher web berjalan otomatis di `http://127.0.0.1:18800` dan tidak diekspos
  ke jaringan lokal secara default. Port yang dapat dipilih berada pada rentang
  aman `1024–65535`; port sistem dan port yang diblokir browser ditolak.
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
`picoclaw-launcher` mempertahankan perilaku launcher PicoClaw.

Gunakan update modul dari KSU Next untuk memperbarui instalasi. Perintah
Perintah `picoclaw update` hanya memperbarui satu binary dan tidak memperbarui
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

Laporan diagnostics hanya memuat status dan metadata runtime yang aman. Isi
`config.json`, API key, password, cookie, token, serta log credential tidak
pernah disalin ke laporan. Log yang ditampilkan dan diekspor diredaksi dengan
nilai `[REDACTED]`; mode **Raw log** hanya mempertahankan format whitespace dan
tidak menonaktifkan redaksi.

Service log memiliki batas ringkas (maksimum 500 baris per permintaan). **Pause**
menahan snapshot lokal meskipun refresh status berkala tetap berjalan; **Live
tail** kembali mengikuti log terbaru. Filter level bersifat heuristik dan
mengklasifikasikan kata error/fatal/panic/gagal sebagai error, warn/warning
sebagai warning, dan sisanya sebagai info.

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

## Versi dan otomasi release

Workflow `Build fork release` hanya mengambil commit dari
`As-tsaqib/picoclaw` branch `main`, lalu melakukan alur berikut:

1. mengambil SHA commit fork melalui GitHub API;
2. membandingkannya dengan `BUILT_SOURCE_REF`, `BUILT_SOURCE_COMMIT`, dan
   `MODULE_VERSION`;
3. checkout SHA fork yang sama dan memverifikasi remote repository;
4. memakai versi Go dari `go.mod` fork, menerapkan patch kompatibilitas Android
   bila diperlukan, membangun frontend dengan lockfile pnpm, lalu menjalankan
   target Android PicoClaw;
5. memvalidasi kedua ELF ARM64, merakit ZIP module, dan membuat checksum;
6. menerbitkan GitHub Release dengan tag versi module serta memperbarui
   `update.json`.

`MODULE_VERSION` adalah source-of-truth versi module dan saat ini bernilai
`1.0.0`. Naikkan patch/minor/major file tersebut ketika kode module atau
kompatibilitas paket berubah. Jika commit fork berubah setelah release module
tersedia, workflow menaikkan patch module secara otomatis. `SOURCE_REF`
mencatat ref fork yang digunakan untuk build.

Workflow juga dapat dijalankan manual dari tab Actions. Mode `force` membangun
ulang dengan versi module yang sedang aktif.

## Build lokal

Dependensi: Bash, Go sesuai `picoclaw-source/go.mod`, Node.js, npm/pnpm, `make`, `zip`,
`file`, serta compiler ARM64 dari Android NDK. Di Termux compiler
`aarch64-linux-android-clang` dideteksi otomatis. Pada host Linux lain, arahkan
`PICOCLAW_ANDROID_CC` ke compiler NDK dan pilih API minimum dengan
`PICOCLAW_ANDROID_API` (default 21).

```sh
git clone --branch main --single-branch https://github.com/As-tsaqib/picoclaw.git picoclaw-source
PICOCLAW_ANDROID_CC="$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android21-clang" \
  make build SOURCE_DIR="$PWD/picoclaw-source" SOURCE_REF=main
```

Artefak berada di `dist/`. Jalankan `make test` untuk pemeriksaan statis,
tes perakitan ZIP, dan regression test backup/restore. Jalankan
`make webui-check` untuk membangun frontend dari `webui/package-lock.json` dan
 memastikan `module/webroot/` sinkron. Build fork menggunakan Git worktree
sementara sehingga source checkout tetap bersih setelah patch Android dan
kompilasi selesai.

Di WebUI, **Module Version** adalah versi paket KSU/Magisk, sedangkan
**Binary Version** adalah nilai `VERSION` yang ditanamkan ke binary PicoClaw
saat build. Keduanya sengaja ditampilkan terpisah.

## Lisensi

Kode modul menggunakan lisensi MIT. PicoClaw juga berlisensi MIT; lisensi source
fork selalu disertakan di dalam ZIP. Lihat [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
