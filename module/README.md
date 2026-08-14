# PicoClaw module

Data persisten berada di `/data/adb/picoclaw`. Buka WebUI modul dari KSU Next
untuk mengelola launcher, atau akses dashboard PicoClaw di
`http://127.0.0.1:18800`. Port launcher yang dapat dipilih berada pada rentang
aman `1024–65535`; port privileged atau yang diblokir browser ditolak.

WebUI menampilkan **Module Version** dan **Binary Version** secara terpisah.
Versi modul mengikuti SemVer independen mulai `1.0.0`; versi binary berasal dari
source fork PicoClaw yang digunakan saat build.

WebUI juga menyediakan Health & Diagnostics untuk status HTTP, uptime, PID,
watchdog, pemeriksaan binary/permission/config/listener/wrapper, serta salinan
laporan aman tanpa API key. Service Logs dapat difilter menurut level,
dijeda/diikuti live, diekspor, di-wrap atau dilihat raw, dan selalu meredaksi
token/password/secret. Clear meminta konfirmasi.

Wrapper Termux dipasang otomatis bila Termux sudah terpasang. Tombol **Action**
menampilkan diagnostik dan menyinkronkan wrapper; lifecycle launcher dikelola
melalui WebUI atau `picoclaw-ctl`.
