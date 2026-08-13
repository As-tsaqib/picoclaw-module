# Third-party notices

Binary `picoclaw` dan `picoclaw-launcher` dibuat langsung dari
[`As-tsaqib/picoclaw`](https://github.com/As-tsaqib/picoclaw), satu-satunya
source repository yang dipakai workflow packing module. Source fork
memakai module path Go mandiri `github.com/As-tsaqib/picoclaw` dan distribusinya
mengikuti lisensi MIT. Salinan lisensi source PicoClaw ikut dimasukkan ke setiap
ZIP modul sebagai `LICENSE.picoclaw`.

Build Android dapat mengubah build constraint stub system tray source fork agar
launcher headless dapat memakai cgo dan resolver Bionic/netd. Patch sumber
lengkap tersedia di `patches/android-cgo-systray.patch` dan tetap berada di
bawah lisensi MIT PicoClaw.

Kode modul, skrip integrasi Android, dan WebUI di repo ini juga menggunakan
lisensi MIT sebagaimana tercantum dalam `LICENSE`.
