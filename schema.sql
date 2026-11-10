-- =====================================================================
--  HỆ THỐNG TÌM KIẾM NHÀ TRỌ VÀ GHÉP BẠN CÙNG PHÒNG
--  File: schema.sql  —  Tạo CSDL và các bảng (DDL)
--  Hệ quản trị: MySQL 8.0.16 trở lên (cần hỗ trợ ràng buộc CHECK)
-- =====================================================================

DROP DATABASE IF EXISTS nha_tro_db;
CREATE DATABASE nha_tro_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;
USE nha_tro_db;

-- ---------------------------------------------------------------------
-- 1. NGUOI_DUNG: người dùng (người tìm phòng, người tìm bạn, chủ trọ)
-- ---------------------------------------------------------------------
CREATE TABLE NGUOI_DUNG (
    MaND          INT           NOT NULL AUTO_INCREMENT,
    HoTen         VARCHAR(100)  NOT NULL,
    NgaySinh      DATE          NOT NULL,
    QueQuan       VARCHAR(100),
    GioiTinh      VARCHAR(5)    NOT NULL,
    SoDienThoai   VARCHAR(10)   NOT NULL,
    Email         VARCHAR(100)  NOT NULL,
    CONSTRAINT pk_nguoidung PRIMARY KEY (MaND),
    CONSTRAINT uq_nguoidung_sdt   UNIQUE (SoDienThoai),
    CONSTRAINT uq_nguoidung_email UNIQUE (Email),
    CONSTRAINT ck_nguoidung_gioitinh CHECK (GioiTinh IN ('Nam', 'Nữ')),
    CONSTRAINT ck_nguoidung_sdt      CHECK (SoDienThoai REGEXP '^0[0-9]{9}$'),
    CONSTRAINT ck_nguoidung_email    CHECK (Email LIKE '%_@_%._%')
) ENGINE = InnoDB COMMENT = 'Thông tin người dùng';

-- ---------------------------------------------------------------------
-- 2. NHA_TRO: nhà trọ, mỗi nhà thuộc sở hữu của một người dùng (chủ trọ)
--    Số điện thoại chủ trọ lấy qua JOIN với NGUOI_DUNG
-- ---------------------------------------------------------------------
CREATE TABLE NHA_TRO (
    MaNT        INT           NOT NULL AUTO_INCREMENT,
    MaND        INT           NOT NULL COMMENT 'Chủ trọ (quan hệ Sở hữu)',
    TenNhaTro   VARCHAR(100)  NOT NULL,
    DiaChi      VARCHAR(255)  NOT NULL,
    KhuVuc      VARCHAR(50)   NOT NULL COMMENT 'Tên quận/huyện, VD: Hà Đông',
    CONSTRAINT pk_nhatro PRIMARY KEY (MaNT),
    CONSTRAINT fk_nhatro_nguoidung FOREIGN KEY (MaND)
        REFERENCES NGUOI_DUNG (MaND)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE = InnoDB COMMENT = 'Thông tin nhà trọ';

-- ---------------------------------------------------------------------
-- 3. PHONG_TRO: phòng trọ, mỗi phòng thuộc một nhà trọ (quan hệ Gồm)
-- ---------------------------------------------------------------------
CREATE TABLE PHONG_TRO (
    MaPT            INT            NOT NULL AUTO_INCREMENT,
    MaNT            INT            NOT NULL,
    DienTich        DECIMAL(5,1)   NOT NULL COMMENT 'm2',
    GiaThue         DECIMAL(12,0)  NOT NULL COMMENT 'VNĐ/tháng',
    TienDien        DECIMAL(10,0)  NOT NULL COMMENT 'VNĐ/kWh',
    TienNuoc        DECIMAL(10,0)  NOT NULL COMMENT 'VNĐ/m3',
    NoiThat         VARCHAR(255)   COMMENT 'VD: giường, tủ, điều hòa',
    SoNguoiOToiDa   TINYINT        NOT NULL,
    TinhTrangPhong  VARCHAR(10)    NOT NULL DEFAULT 'Trống',
    CONSTRAINT pk_phongtro PRIMARY KEY (MaPT),
    CONSTRAINT fk_phongtro_nhatro FOREIGN KEY (MaNT)
        REFERENCES NHA_TRO (MaNT)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT ck_phongtro_dientich  CHECK (DienTich > 0),
    CONSTRAINT ck_phongtro_giathue   CHECK (GiaThue > 0),
    CONSTRAINT ck_phongtro_tiendien  CHECK (TienDien >= 0),
    CONSTRAINT ck_phongtro_tiennuoc  CHECK (TienNuoc >= 0),
    CONSTRAINT ck_phongtro_songuoi   CHECK (SoNguoiOToiDa BETWEEN 1 AND 10),
    CONSTRAINT ck_phongtro_tinhtrang CHECK (TinhTrangPhong IN ('Trống', 'Đã thuê'))
) ENGINE = InnoDB COMMENT = 'Thông tin phòng trọ';

-- ---------------------------------------------------------------------
-- 4. HINH_ANH_PHONG: một phòng có nhiều hình ảnh (quan hệ Có ảnh)
-- ---------------------------------------------------------------------
CREATE TABLE HINH_ANH_PHONG (
    MaHA        INT           NOT NULL AUTO_INCREMENT,
    MaPT        INT           NOT NULL,
    TenHinhAnh  VARCHAR(100)  NOT NULL,
    DuongDan    VARCHAR(255)  NOT NULL,
    CONSTRAINT pk_hinhanh PRIMARY KEY (MaHA),
    CONSTRAINT fk_hinhanh_phongtro FOREIGN KEY (MaPT)
        REFERENCES PHONG_TRO (MaPT)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE = InnoDB COMMENT = 'Hình ảnh phòng trọ';

-- ---------------------------------------------------------------------
-- 5. TIEN_ICH: danh mục tiện ích dùng chung cho mọi nhà trọ
-- ---------------------------------------------------------------------
CREATE TABLE TIEN_ICH (
    MaTI        INT           NOT NULL AUTO_INCREMENT,
    TenTienIch  VARCHAR(100)  NOT NULL,
    MoTa        VARCHAR(255),
    CONSTRAINT pk_tienich PRIMARY KEY (MaTI),
    CONSTRAINT uq_tienich_ten UNIQUE (TenTienIch)
) ENGINE = InnoDB COMMENT = 'Danh mục tiện ích';

-- ---------------------------------------------------------------------
-- 6. NHATRO_TIENICH: bảng trung gian cho quan hệ N-N "Có tiện ích"
-- ---------------------------------------------------------------------
CREATE TABLE NHATRO_TIENICH (
    MaNT  INT  NOT NULL,
    MaTI  INT  NOT NULL,
    CONSTRAINT pk_nhatro_tienich PRIMARY KEY (MaNT, MaTI),
    CONSTRAINT fk_ntti_nhatro FOREIGN KEY (MaNT)
        REFERENCES NHA_TRO (MaNT)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_ntti_tienich FOREIGN KEY (MaTI)
        REFERENCES TIEN_ICH (MaTI)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE = InnoDB COMMENT = 'Tiện ích của từng nhà trọ';

-- ---------------------------------------------------------------------
-- 7. BAI_DANG_CHO_THUE: chủ trọ đăng bài cho thuê một phòng
--    (quan hệ Đăng cho thuê với NGUOI_DUNG, quan hệ Thuộc với PHONG_TRO)
-- ---------------------------------------------------------------------
CREATE TABLE BAI_DANG_CHO_THUE (
    MaBDCT     INT          NOT NULL AUTO_INCREMENT,
    MaND       INT          NOT NULL COMMENT 'Người đăng (phải là chủ trọ của phòng)',
    MaPT       INT          NOT NULL,
    NoiDung    TEXT         NOT NULL,
    NgayDang   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    TrangThai  VARCHAR(20)  NOT NULL DEFAULT 'Đang hiển thị',
    CONSTRAINT pk_bdct PRIMARY KEY (MaBDCT),
    CONSTRAINT fk_bdct_nguoidung FOREIGN KEY (MaND)
        REFERENCES NGUOI_DUNG (MaND)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_bdct_phongtro FOREIGN KEY (MaPT)
        REFERENCES PHONG_TRO (MaPT)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT ck_bdct_trangthai CHECK (TrangThai IN ('Đang hiển thị', 'Đã ẩn'))
) ENGINE = InnoDB COMMENT = 'Bài đăng cho thuê phòng';

-- ---------------------------------------------------------------------
-- 8. BAI_DANG_TIM_PHONG: người dùng đăng nhu cầu tìm phòng
-- ---------------------------------------------------------------------
CREATE TABLE BAI_DANG_TIM_PHONG (
    MaBDTP    INT            NOT NULL AUTO_INCREMENT,
    MaND      INT            NOT NULL,
    KhuVuc    VARCHAR(50)    NOT NULL COMMENT 'Khu vực mong muốn',
    GiaToiDa  DECIMAL(12,0)  NOT NULL COMMENT 'VNĐ/tháng',
    DienTich  DECIMAL(5,1)   NOT NULL COMMENT 'Diện tích mong muốn (m2)',
    SoNguoiO  TINYINT        NOT NULL,
    NoiDung   TEXT,
    NgayDang  DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_bdtp PRIMARY KEY (MaBDTP),
    CONSTRAINT fk_bdtp_nguoidung FOREIGN KEY (MaND)
        REFERENCES NGUOI_DUNG (MaND)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT ck_bdtp_gia      CHECK (GiaToiDa > 0),
    CONSTRAINT ck_bdtp_dientich CHECK (DienTich > 0),
    CONSTRAINT ck_bdtp_songuoi  CHECK (SoNguoiO BETWEEN 1 AND 10)
) ENGINE = InnoDB COMMENT = 'Bài đăng tìm phòng';

-- ---------------------------------------------------------------------
-- 9. BAI_DANG_TIM_BAN: người dùng đăng nhu cầu tìm bạn cùng phòng
-- ---------------------------------------------------------------------
CREATE TABLE BAI_DANG_TIM_BAN (
    MaBDTB            INT            NOT NULL AUTO_INCREMENT,
    MaND              INT            NOT NULL,
    KhuVuc            VARCHAR(50)    NOT NULL COMMENT 'Khu vực mong muốn',
    GiaThue           DECIMAL(12,0)  NOT NULL COMMENT 'Mức tiền thuê dự kiến mỗi người (VNĐ/tháng)',
    GioiTinhMongMuon  VARCHAR(15)    NOT NULL,
    NgayBatDau        DATE           NOT NULL,
    ThoiHan           TINYINT        NOT NULL COMMENT 'Số tháng muốn ở',
    NoiDungYeuCau     TEXT,
    NgayDang          DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    TrangThai         VARCHAR(20)    NOT NULL DEFAULT 'Đang tìm',
    CONSTRAINT pk_bdtb PRIMARY KEY (MaBDTB),
    CONSTRAINT fk_bdtb_nguoidung FOREIGN KEY (MaND)
        REFERENCES NGUOI_DUNG (MaND)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT ck_bdtb_gia       CHECK (GiaThue > 0),
    CONSTRAINT ck_bdtb_gioitinh  CHECK (GioiTinhMongMuon IN ('Nam', 'Nữ', 'Không yêu cầu')),
    CONSTRAINT ck_bdtb_thoihan   CHECK (ThoiHan BETWEEN 1 AND 60),
    CONSTRAINT ck_bdtb_trangthai CHECK (TrangThai IN ('Đang tìm', 'Đã tìm được'))
) ENGINE = InnoDB COMMENT = 'Bài đăng tìm bạn cùng phòng';

-- =====================================================================
--  CHỈ MỤC (INDEX) cho các cột hay dùng để lọc trong 8 truy vấn
--  (khóa ngoại đã được MySQL tự tạo chỉ mục)
-- =====================================================================
CREATE INDEX idx_nhatro_khuvuc       ON NHA_TRO (KhuVuc);
CREATE INDEX idx_phongtro_tt_gia     ON PHONG_TRO (TinhTrangPhong, GiaThue);
CREATE INDEX idx_bdtp_khuvuc_gia     ON BAI_DANG_TIM_PHONG (KhuVuc, GiaToiDa);
CREATE INDEX idx_bdtb_khuvuc_gia     ON BAI_DANG_TIM_BAN (KhuVuc, GiaThue);

-- =====================================================================
--  TRIGGER: đảm bảo người đăng bài cho thuê đúng là chủ của nhà trọ
--  chứa phòng đó (giải quyết vòng quan hệ NGUOI_DUNG - BAI_DANG_CHO_THUE
--  - PHONG_TRO - NHA_TRO - NGUOI_DUNG trong lược đồ ER)
-- =====================================================================
DELIMITER $$

CREATE TRIGGER trg_bdct_chu_tro_insert
BEFORE INSERT ON BAI_DANG_CHO_THUE
FOR EACH ROW
BEGIN
    IF NEW.MaND <> (SELECT nt.MaND
                    FROM PHONG_TRO pt
                    JOIN NHA_TRO nt ON nt.MaNT = pt.MaNT
                    WHERE pt.MaPT = NEW.MaPT) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Nguoi dang bai phai la chu cua nha tro chua phong nay';
    END IF;
END$$

CREATE TRIGGER trg_bdct_chu_tro_update
BEFORE UPDATE ON BAI_DANG_CHO_THUE
FOR EACH ROW
BEGIN
    IF NEW.MaND <> (SELECT nt.MaND
                    FROM PHONG_TRO pt
                    JOIN NHA_TRO nt ON nt.MaNT = pt.MaNT
                    WHERE pt.MaPT = NEW.MaPT) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Nguoi dang bai phai la chu cua nha tro chua phong nay';
    END IF;
END$$

DELIMITER ;
