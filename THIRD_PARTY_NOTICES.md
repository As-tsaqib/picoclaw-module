# Third-party notices

Binary `picoclaw` dan `picoclaw-launcher` dibuat dari
[`sipeed/picoclaw`](https://github.com/sipeed/picoclaw), yang didistribusikan
dengan lisensi MIT. Salinan lisensi upstream ikut dimasukkan ke setiap ZIP
modul sebagai `LICENSE.picoclaw`.

Build Android mengubah build constraint stub system tray upstream agar launcher
headless dapat memakai cgo dan resolver Bionic/netd. Patch sumber lengkap
tersedia di `patches/android-cgo-systray.patch` dan tetap berada di bawah
lisensi MIT upstream.

Kode modul, skrip integrasi Android, dan WebUI di repo ini juga menggunakan
lisensi MIT sebagaimana tercantum dalam `LICENSE`.
