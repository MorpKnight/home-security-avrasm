# Home Security System with Arduino Using AVR Assembly
## *Kelompok A2 Sistem Siber Fisik*
Merupakan perangkat keamanan untuk rumah, yang dapat mendeteksi keberadaan orang di tempat yang tidak diinginkan. Perangkat ini menggunakan sensor PIR (Passive Infrared) sebagai sensor deteksi gerak, dan buzzer sebagai alarm. Perangkat ini juga dilengkapi dengan kemampuannya melakukan pemrosesan jam, sehingga tidak membutuhkan RTC (Real Time Clock) tambahan.
### Anggota Kelompok
- [Giovan Christoffel Sihombing](https://github.com/MorpKnight) - 2206816084
- [Fathin Umara Aero](https://github.com/rovaero) - 2206814186
- [Rifqi Ramadhan](https://github.com/RifqiRamadhan-creator) - 2206062964
- [Muhammad Fahish Haritsah Bimo](https://github.com/mfharitsah) - 2206059616

## Introduction
Pada zaman ini, keamanan dapat dibilang menjadi hal utama bagi seseorang yang memiliki aset, khususnya rumah. Sebagai pemilih rumah, tentu kita kadang memajang benda benda berharga kita sebagai perhiasan di rumah. Dan tentu kita tidak ingin benda benda berharga tersebut dicuri oleh orang yang tidak bertanggung jawab. Salah satu cara efektif untuk meningkatkan keamanan rumah adalah dengan menggunakan sistem deteksi gerak yang dapat memberi tahu pemilik rumah tentang aktivitas yang tidak biasa. Oleh karena itu, kami membuat sebuah sistem keamanan rumah yang dapat mendeteksi keberadaan orang di tempat yang tidak diinginkan. Sistem ini menggunakan sensor PIR (Passive Infrared) sebagai sensor deteksi gerak, dan buzzer sebagai alarm. Sistem ini juga dilengkapi dengan kemampuannya melakukan pemrosesan jam, sehingga tidak membutuhkan RTC (Real Time Clock) tambahan.

## Hardware Design & Implementation Details
### Components Used
- **PIR Sensor**: Merupakan sensor yang digunakan untuk mendeteksi gerakan, sensor ini memiliki kalibratornya sendiri. Sehingga tidak perlu dilakukannya pemrograman untuk mengonversikan analog menjadi digital (ADC). Kita cukup mengatur threshold-nya saja.
- **Buzzer & LED**:  Digunakan sebagai alarm yang akan aktif ketika gerakan terdeteksi
- **2 Arduino**, 1 sebagai **MASTER** dan 1 sebagai **SLAVE**
- **Breadboard**: Digunakan untuk menyusun rangkaian 
## Software Implementation Details
Untuk software yang diimplementasikan pada sistem keamanan rumah ini adalah sebagai berikut:
- Software menggunakan bahasa Assembly AVR
- **MASTER** akan membaca data dari PIR Sensor secara terus menerus, tanpa mempedulikan apakah itu jam-nya aktif atau tidak. Dan mengirimkannya ke **SLAVE**
- **SLAVE** akan menerima data dari **MASTER**, dan memprosesnya. Jika data yang diterima adalah 0xFF, maka **SLAVE** akan menyalakan Buzzer dan LED
- Namun, jika jam tersebut bukan merupakan jam aktifnya, maka **SLAVE** tidak akan menyalakan Buzzer dan LED, meskipun data yang diterima adalah 0xFF. Kecuali jika **SLAVE** diaktifkan secara manual dengan menekan tombol yang disediakan
## Test Result & Performance Evaluation
Berdasarkan hasil pengujian dan evaluasi yang telah dilakukan, sistem keamanan rumah menggunakan Arduino dengan bahasa Assembly AVR ini dapat berjalan dengan baik. Sistem dapat mampu mendeteksi gerakan yang terjadi di sekitar sensor PIR dan memberikan respons yang sesuai. Selain itu, sistem juga dapat diaktifkan secara manual melalui tombol yang disediakan. Berikut adalah hasil pengujian dan evaluasi yang telah dilakukan:
1. Keadaan sebelum dijalankan
![sebelum dijalankan](https://github.com/MorpKnight/home-security-avrasm/blob/main/image/sebelum%20dijalankan.png)

2. Keadaan setelah dijalankan, jam di set 6 pagi, yang dimana sistem tidak akan aktif
![setelah dijalankan, jam di set 6 pagi, sistem tidak aktif](https://github.com/MorpKnight/home-security-avrasm/blob/main/image/dijalankan_1.png)
3. Keadaan setelah dijalankan, jam di set 6 pagi, sistem diaktifkan secara manual, dan tidak terdeteksi gerakan. Buzzer dan LED tidak akan menyala karena komparator untuk menyalakan Buzzer dan LED hanya ketika data yang dikirim oleh MASTER bernilai 0xFF
![setelah dijalankan, jam di set 6 pagi, sistem diaktifkan secara manual, dan tidak terdeteksi gerakan](https://github.com/MorpKnight/home-security-avrasm/blob/main/image/dijalankan_3.png)
4. Keadaan setelah dijalankan, jam di set 6 pagi, sistem diaktifkan secara manual, dan terdeteksi gerakan. Pada gambar, data yang terlihat pada transmisi dari MASTER ke SLAVE menunjukkan nilai 0xFF. Sehingga Buzzer dan LED aktif
![setelah dijalankan, jam di set 6 pagi, sistem diaktifkan secara manual, dan terdeteksi gerakan](https://github.com/MorpKnight/home-security-avrasm/blob/main/image/dijalankan_2.png)

Secara keseluruhan dapat dikatakan bahwa kode berjalan dengan baik dan sesuai dengan yang diharapkan. Sistem dapat mendeteksi gerakan yang terjadi di sekitar sensor PIR dan memberikan respons yang sesuai. Selain itu, sistem juga dapat diaktifkan secara manual melalui tombol yang disediakan.

## Conclusion & Future Work
Perangkat ini telah memenuhi syarat untuk membantu keamanan rumah. Namun, terdapat beberapa pengembangan yang dapat dikembangkan, seperti:
- Dapat mengganti BAHASA yang digunakan menjadi lebih bersahabat, sehingga kostumisasi menjadi lebih mudah
- Perangkat yang digunakan dapat diganti perangkat lain, contohnya dapat menggunakan ESP atau perangkat IoT lainnya
- Fitur fitur seperti mengirimkan *alerts* menggunakan SMS dapat ditambahkan
- Apabila dengan menggunakan ESP module, maka kita dapat mengintegrasikannya dengan home automation lainnya
- Menambahkan beberapa jenis sensor lainnya, sehingga sistem keamanan rumah menjadi lebih kompleks