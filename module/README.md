# PicoClaw module

Data persisten berada di `/data/adb/picoclaw`. Buka WebUI modul dari KSU Next
untuk mengelola launcher, atau akses dashboard PicoClaw di
`http://127.0.0.1:18800`.

WebUI menampilkan **Module Version** dan **Binary Version** secara terpisah.
Versi modul mengikuti SemVer independen mulai `1.0.0`; versi binary berasal dari
source fork PicoClaw yang digunakan saat build.

Wrapper Termux dipasang otomatis bila Termux sudah terpasang. Tombol **Action**
menampilkan diagnostik dan menyinkronkan wrapper; lifecycle launcher dikelola
melalui WebUI atau `picoclaw-ctl`.
