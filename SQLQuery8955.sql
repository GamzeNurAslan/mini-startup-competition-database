
USE quizson;
GO

DROP TRIGGER IF EXISTS dbo.trg_JuriDegerlendirme_AfterIU;
DROP PROCEDURE IF EXISTS dbo.sp_KazananBelirle;
DROP PROCEDURE IF EXISTS dbo.sp_PuanVer;

DROP TABLE IF EXISTS dbo.Kazanan;
DROP TABLE IF EXISTS dbo.JuriDegerlendirmesi;
DROP TABLE IF EXISTS dbo.Oduller;
DROP TABLE IF EXISTS dbo.Etkinlik_Juriler;
DROP TABLE IF EXISTS dbo.Juriler;
DROP TABLE IF EXISTS dbo.Startuplar;
DROP TABLE IF EXISTS dbo.Yarisma_Etkinlikleri;
DROP TABLE IF EXISTS dbo.Kullanicilar;

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

-- 1) Kullanicilar
CREATE TABLE dbo.Kullanicilar (
    id                  INT IDENTITY(1,1) PRIMARY KEY,
    ad_soyad            NVARCHAR(255) NOT NULL,
    email               NVARCHAR(255) NOT NULL,
    sifre               NVARCHAR(255) NOT NULL,
    rol                 NVARCHAR(255) NOT NULL,
    telefon             NVARCHAR(255) NOT NULL,
    olusturma_tarihi    DATETIME NOT NULL CONSTRAINT kullanicilar_olusturma DEFAULT (GETDATE()),
    CONSTRAINT kullanicilar_email UNIQUE (email),
    CONSTRAINT kullanicilar_rol CHECK (rol IN ('ADMIN','ORGANIZATOR','JURI','TEMSILCI'))
);
GO

-- 2) Yarisma_Etkinlikleri
CREATE TABLE dbo.Yarisma_Etkinlikleri (
    id                      INT IDENTITY(1,1) PRIMARY KEY,
    ad                      NVARCHAR(255) NOT NULL,
    baslangic_tarihi        DATE NOT NULL,
    bitis_tarihi            DATE NOT NULL,
    konum                   NVARCHAR(255) NULL,
    aciklama                NVARCHAR(1000) NULL,
    FK_olusturan_kullanici_id INT NOT NULL,
    CONSTRAINT etkinlik_olusturan FOREIGN KEY (FK_olusturan_kullanici_id) REFERENCES dbo.Kullanicilar(id),
    CONSTRAINT etkinlik_tarih CHECK (bitis_tarihi >= baslangic_tarihi)
);
GO

-- 3) Startuplar
CREATE TABLE dbo.Startuplar (
    id                      INT IDENTITY(1,1) PRIMARY KEY,
    ad                      NVARCHAR(255) NOT NULL,
    kategori                NVARCHAR(255) NOT NULL,
    aciklama                NVARCHAR(1000) NULL,
    web_site                NVARCHAR(255) NULL,
    FK_temsilci_kullanici_id INT NOT NULL,
    FK_etkinlik_id          INT NOT NULL,
    olusturma_tarihi        DATETIME NOT NULL CONSTRAINT startuplar_olusturma DEFAULT (GETDATE()),
    CONSTRAINT startup_temsilci FOREIGN KEY (FK_temsilci_kullanici_id) REFERENCES dbo.Kullanicilar(id),
    CONSTRAINT startup_etkinlik FOREIGN KEY (FK_etkinlik_id) REFERENCES dbo.Yarisma_Etkinlikleri(id),
    CONSTRAINT startup_etkinlik_ad UNIQUE (FK_etkinlik_id, ad)
);
GO

-- 4) Juriler
CREATE TABLE dbo.Juriler (
    id                  INT IDENTITY(1,1) PRIMARY KEY,
    FK_kullanici_id      INT NOT NULL,
    uzmanlik_alani       NVARCHAR(255) NULL,
    biyografi            NVARCHAR(2000) NULL,
    aktif_mi             BIT NOT NULL CONSTRAINT juri_aktif DEFAULT (1),
    CONSTRAINT juriler_kullanici UNIQUE (FK_kullanici_id),
    CONSTRAINT juri_kullanici FOREIGN KEY (FK_kullanici_id) REFERENCES dbo.Kullanicilar(id)
);
GO

-- 5) Etkinlik_Juriler
CREATE TABLE dbo.Etkinlik_Juriler (
    etkinlik_id  INT NOT NULL,
    juri_id      INT NOT NULL,
    atama_tarihi DATETIME NOT NULL CONSTRAINT etkinlikJuri_atama DEFAULT (GETDATE()),
    PRIMARY KEY (etkinlik_id, juri_id),
    CONSTRAINT EJ_Etkinlik FOREIGN KEY (etkinlik_id) REFERENCES dbo.Yarisma_Etkinlikleri(id),
    CONSTRAINT EJ_Juri FOREIGN KEY (juri_id) REFERENCES dbo.Juriler(id)
);
GO

-- 6) Oduller
CREATE TABLE dbo.Oduller (
    id              INT IDENTITY(1,1) PRIMARY KEY,
    FK_etkinlik_id  INT NOT NULL,
    ad              NVARCHAR(255) NOT NULL,
    derece          INT NOT NULL,         
    sponsor         NVARCHAR(255) NULL,
    aciklama        NVARCHAR(1000) NULL,
    CONSTRAINT odul_etkinlik FOREIGN KEY (FK_etkinlik_id) REFERENCES dbo.Yarisma_Etkinlikleri(id),
    CONSTRAINT odul_derece CHECK (derece >= 1),
    CONSTRAINT odul_etkinlik_derece UNIQUE (FK_etkinlik_id, derece)
);
GO

-- 7) JuriDegerlendirmesi
CREATE TABLE dbo.JuriDegerlendirmesi (
    id                  INT IDENTITY(1,1) PRIMARY KEY,
    FK_juri_id          INT NOT NULL,
    FK_startup_id       INT NOT NULL,
    FK_etkinlik_id      INT NOT NULL,

    yenilikcilik_puani  TINYINT NOT NULL,
    is_modeli_puani     TINYINT NOT NULL,
    teknoloji_puani     TINYINT NOT NULL,
    sunum_puani         TINYINT NOT NULL,

    toplam_puan AS (yenilikcilik_puani + is_modeli_puani + teknoloji_puani + sunum_puani) PERSISTED,

    yorum               NVARCHAR(2500) NULL,

    CONSTRAINT JD_Juri FOREIGN KEY (FK_juri_id) REFERENCES dbo.Juriler(id),
    CONSTRAINT JD_Startup FOREIGN KEY (FK_startup_id) REFERENCES dbo.Startuplar(id),
    CONSTRAINT JD_Etkinlik FOREIGN KEY (FK_etkinlik_id) REFERENCES dbo.Yarisma_Etkinlikleri(id),

    CONSTRAINT JD_TekilDegerlendirme UNIQUE (FK_juri_id, FK_startup_id, FK_etkinlik_id),

    CONSTRAINT JD_Puan1 CHECK (yenilikcilik_puani BETWEEN 0 AND 10),
    CONSTRAINT JD_Puan2 CHECK (is_modeli_puani BETWEEN 0 AND 10),
    CONSTRAINT JD_Puan3 CHECK (teknoloji_puani BETWEEN 0 AND 10),
    CONSTRAINT JD_Puan4 CHECK (sunum_puani BETWEEN 0 AND 10)
);
GO

-- 8) Kazanan
CREATE TABLE dbo.Kazanan (
    id                      INT IDENTITY(1,1) PRIMARY KEY,
    FK_etkinlik_id          INT NOT NULL,
    FK_startup_id           INT NOT NULL,
    FK_odul_id              INT NULL,
    FK_temsilci_kullanici_id INT NOT NULL,
    gerekce                 NVARCHAR(2000) NULL,
    teslim_tarihi           DATE NULL,

    CONSTRAINT KZ_Etkinlik FOREIGN KEY (FK_etkinlik_id) REFERENCES dbo.Yarisma_Etkinlikleri(id),
    CONSTRAINT KZ_Startup FOREIGN KEY (FK_startup_id) REFERENCES dbo.Startuplar(id),
    CONSTRAINT KZ_Odul_UNIQ FOREIGN KEY (FK_odul_id) REFERENCES dbo.Oduller(id),
    CONSTRAINT KZ_Temsilci FOREIGN KEY (FK_temsilci_kullanici_id) REFERENCES dbo.Kullanicilar(id),

    CONSTRAINT KZ_Etkinlik_Startup UNIQUE (FK_etkinlik_id, FK_startup_id),
    CONSTRAINT KZ_Odul UNIQUE (FK_odul_id) 
);
GO

-- SP: Jüri Puan Ver
CREATE OR ALTER PROCEDURE dbo.sp_PuanVer
    @juri_id        INT,
    @etkinlik_id    INT,
    @startup_id     INT,
    @yenilikcilik   TINYINT,
    @is_modeli      TINYINT,
    @teknoloji      TINYINT,
    @sunum          TINYINT,
    @yorum          NVARCHAR(2000) NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Jüri atanmýþ ve aktif mi?
    IF NOT EXISTS (
        SELECT 1 FROM dbo.Etkinlik_Juriler ej
        JOIN dbo.Juriler j ON j.id = ej.juri_id
        WHERE ej.etkinlik_id=@etkinlik_id AND ej.juri_id=@juri_id AND j.aktif_mi=1
    )
        THROW 50001, 'Bu jüri bu etkinliðe atanmadýðý veya aktif olmadýðý için puan veremez', 1;

    -- Startup bu etkinliðe ait mi?
    IF NOT EXISTS (
        SELECT 1 FROM dbo.Startuplar
        WHERE id=@startup_id AND FK_etkinlik_id=@etkinlik_id
    )
        THROW 50002, 'Startup belirtilen etkinliðe ait deðil', 1;

    -- Puan aralýðý 0-10
    IF (@yenilikcilik>10 OR @is_modeli>10 OR @teknoloji>10 OR @sunum>10)
        THROW 50003, 'Puanlar 0-10 aralýðýnda olmalýdýr.', 1;

    -- UPSERT
    IF EXISTS (
        SELECT * FROM dbo.JuriDegerlendirmesi
        WHERE FK_juri_id=@juri_id AND FK_startup_id=@startup_id AND FK_etkinlik_id=@etkinlik_id
    )
        UPDATE dbo.JuriDegerlendirmesi
        SET yenilikcilik_puani=@yenilikcilik,
            is_modeli_puani=@is_modeli,
            teknoloji_puani=@teknoloji,
            sunum_puani=@sunum,
            yorum=@yorum
        WHERE FK_juri_id=@juri_id AND FK_startup_id=@startup_id AND FK_etkinlik_id=@etkinlik_id;
    ELSE
        INSERT INTO dbo.JuriDegerlendirmesi
            (FK_juri_id, FK_startup_id, FK_etkinlik_id,
             yenilikcilik_puani, is_modeli_puani, teknoloji_puani, sunum_puani, yorum)
        VALUES
            (@juri_id, @startup_id, @etkinlik_id,
             @yenilikcilik, @is_modeli, @teknoloji, @sunum, @yorum);
END
GO

-- SP: Kazanan Belirle
CREATE OR ALTER PROCEDURE dbo.sp_KazananBelirle
    @etkinlik_id INT,
    @derece      INT,
    @gerekce     NVARCHAR(2000) NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRAN;

        IF EXISTS (SELECT 1 FROM dbo.Yarisma_Etkinlikleri WHERE id=@etkinlik_id AND bitis_tarihi>GETDATE())
            THROW 50010, 'Etkinlik bitmeden kazanan belirlenemez', 1;

        DECLARE @odul_id INT;
        SELECT @odul_id = id FROM dbo.Oduller WHERE FK_etkinlik_id=@etkinlik_id AND derece=@derece;
        IF @odul_id IS NULL
            THROW 50011, 'Belirtilen dereceye ait ödül bulunamadý', 1;

        IF EXISTS (SELECT 1 FROM dbo.Kazanan WHERE FK_odul_id=@odul_id)
            THROW 50012, 'Bu ödül zaten bir kazanana atanmýþ.', 1;

        DECLARE @startup_id INT;
        SELECT TOP 1 @startup_id = FK_startup_id
        FROM dbo.JuriDegerlendirmesi
        WHERE FK_etkinlik_id=@etkinlik_id
        GROUP BY FK_startup_id
        ORDER BY AVG(CAST(toplam_puan AS DECIMAL)) DESC, FK_startup_id ASC;

        IF @startup_id IS NULL
            THROW 50013, 'Kazanan belirlemek için deðerlendirme bulunamadý', 1;

        -- Ayný startup zaten kazandý mý?
        IF EXISTS (SELECT * FROM dbo.Kazanan WHERE FK_etkinlik_id=@etkinlik_id AND FK_startup_id=@startup_id)
            THROW 50016, 'Bu startup zaten bir derece kazanmýþ', 1;

        DECLARE @temsilci_id INT;
        SELECT @temsilci_id = FK_temsilci_kullanici_id FROM dbo.Startuplar WHERE id=@startup_id;

        INSERT INTO dbo.Kazanan
            (FK_etkinlik_id, FK_startup_id, FK_odul_id, FK_temsilci_kullanici_id, gerekce, teslim_tarihi)
        VALUES
            (@etkinlik_id, @startup_id, @odul_id, @temsilci_id, @gerekce, NULL);

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT>0 ROLLBACK;
        THROW;
    END CATCH
END
GO

-- Trigger: JuriDegerlendirmesi
CREATE TRIGGER dbo.trg_JuriDegerlendirme_AfterIU
ON dbo.JuriDegerlendirmesi
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN dbo.Startuplar s ON s.id = i.FK_startup_id
        WHERE s.FK_etkinlik_id <> i.FK_etkinlik_id
    )
    BEGIN
        ROLLBACK;
        THROW 50021, 'Deðerlendirme: Startup etkinlik uyuþmazlýðý tespit edildi.', 1;
    END
END
GO

-- 7.1 ORNEK VERILER (INSERT)
-- once kullanicilar, sonra etkinlik, startup, juri vs.

-- 1) Kullanicilar
INSERT INTO dbo.Kullanicilar(ad_soyad,email,sifre,rol,telefon)
VALUES
('Gamze Nur Aslan','gmzorg@mail.com','123','ORGANIZATOR','5000000000'),
('Büþra Yaþar','bsrjuri@mail.com','123','JURI','5000000001'),
('Rua Melhem','ruajuri@mail.com','123','JURI','5000000002'),
('Ertan Bütün','erttemsilci@mail.com','123','TEMSILCI','5000000003'),
('Zeynep Küçük','zynptemsilci@mail.com','123','TEMSILCI','5000000004');
GO

-- 2) Yarisma_Etkinlikleri (olusturan kullanici = 1)
INSERT INTO dbo.Yarisma_Etkinlikleri(ad,baslangic_tarihi,bitis_tarihi,konum,aciklama,FK_olusturan_kullanici_id)
VALUES
('Mini Startup 2025','2025-12-20','2025-12-25','Istanbul','deneme etkinligi',1),
('Mini Startup 2026','2026-01-10','2026-01-15','Ankara','ikinci etkinlik',1);
GO

-- 3) Startuplar (etkinlik 1 ve 2'ye bagli)
INSERT INTO dbo.Startuplar(ad,kategori,aciklama,web_site,FK_temsilci_kullanici_id,FK_etkinlik_id)
VALUES
('GreenAI','Afet Teknolojileri','afet icin cozum','https://a.com',4,1),
('CampusWise','Akilli Kampus','kampus otomasyon','https://b.com',5,1),
('SecureEdu','Dijital Guvenlik','guvenli giris','https://c.com',4,2);
GO

-- 4) Juriler (kullanici 2 ve 3 juri olsun)
INSERT INTO dbo.Juriler(FK_kullanici_id,uzmanlik_alani,biyografi,aktif_mi)
VALUES
(2,'VC','juri 1',1),
(3,'Teknoloji','juri 2',1);
GO

-- 5) Etkinlik_Juriler (1. etkinlige 2 juri, 2. etkinlige 1 juri)
INSERT INTO dbo.Etkinlik_Juriler(etkinlik_id,juri_id)
VALUES
(1,1),
(1,2),
(2,2);
GO

-- 6) Oduller
INSERT INTO dbo.Oduller(FK_etkinlik_id,ad,derece,sponsor,aciklama)
VALUES
(1,'Birincilik',1,'SponsorA','1.lik odulu'),
(1,'Ikincilik',2,'SponsorB','2.lik odulu'),
(2,'Birincilik',1,'SponsorC','1.lik odulu');
GO

--Test 1: Doðru etkinlik ile deðerlendirme ekleme (hata olmamalý)
INSERT INTO dbo.JuriDegerlendirmesi
(FK_juri_id, FK_startup_id, FK_etkinlik_id, yenilikcilik_puani, is_modeli_puani, teknoloji_puani, sunum_puani, yorum)
VALUES
(1, 1, 1, 8, 8, 8, 8, N'doðru etkinlik');

-- 7) JuriDegerlendirmesi (SP ile puan veriyoruz)
EXEC dbo.sp_PuanVer 1,1,1, 9,8,9,8, N'iyi proje';
EXEC dbo.sp_PuanVer 2,1,1, 8,8,9,7, N'sunum biraz zayif';
EXEC dbo.sp_PuanVer 1,1,2, 7,7,8,7, N'fena degil';
EXEC dbo.sp_PuanVer 2,1,2, 7,6,7,6, N'gelistirilebilir';
EXEC dbo.sp_PuanVer 2,2,3, 8,7,8,7, N'genel olarak iyi';
GO

-- 8) Kazanan belirlemek icin etkinlik 1'in bitis tarihini gecmise cekiyorum (test icin)
UPDATE dbo.Yarisma_Etkinlikleri
SET bitis_tarihi = CAST(GETDATE() AS DATE)
WHERE id = 1;
GO

-- Kazanan belirle (etkinlik 1, derece 1)
EXEC dbo.sp_KazananBelirle 1, 1, N'ortalama puani en yuksek';
GO

--Hata Senaryosu ve ROLLBACK Testi
--EXEC dbo.sp_KazananBelirle 1, 1, N'tekrar deneme';

-- kontrol icin
SELECT * FROM dbo.Kullanicilar;
SELECT * FROM dbo.Yarisma_Etkinlikleri;
SELECT * FROM dbo.Startuplar;
SELECT * FROM dbo.Juriler;
SELECT * FROM dbo.Etkinlik_Juriler;
SELECT * FROM dbo.Oduller;
SELECT * FROM dbo.JuriDegerlendirmesi;
SELECT * FROM dbo.Kazanan;
SELECT * FROM dbo.JuriDegerlendirmesi
WHERE FK_juri_id=1 AND FK_startup_id=1 AND FK_etkinlik_id=1;
GO