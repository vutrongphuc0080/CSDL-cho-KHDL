# Câu 1: Hãy viết câu lệnh SQL để tính sự tương quan giữa A và B theo công thức sau:
DROP TABLE data
CREATE TABLE data (
    A INT,
    B INT
);

INSERT INTO data (A, B) VALUES
(1, 2),
(2, 4),
(3, 6),
(4, 8),
(5, 10);
WITH stats AS (
    SELECT
        COUNT(*) AS n,
        SUM(A * B) AS sum_ab,
        SUM(A) AS sum_a,
        SUM(B) AS sum_b,
        SUM(A * A) AS sum_a2,
        SUM(B * B) AS sum_b2
    FROM data
)
SELECT
    (n * sum_ab - sum_a * sum_b) / 
    SQRT((n * sum_a2 - sum_a * sum_a) * (n * sum_b2 - sum_b * sum_b)) AS correlation
FROM stats;

# Câu 2: Một công ty oto đang kiểm tra 3 loại mẫu mới A, B và C trong 4 ngày, và chấm điểm theo thang từ 1 đến 10 điểm cho mỗi ngày với bảng sau. Liệu có sự khác biệt đáng kể giữa các mẫu dựa trên điểm số mà
chúng nhận được trong 4 ngày thử nghiệm không? Kết quả thử nghiệm phụ thuộc vào ngày hay phụ thuộc vào mẫu xe? Hãy chuyển đổi dữ liệu sang dạng quan hệ và thực hiện kiểm tra χ2.
DROP TABLE scores;
-- 1. Tạo bảng và chèn dữ liệu
CREATE TABLE scores (
    Day VARCHAR(10),
    Model VARCHAR(1),
    Score FLOAT
);

INSERT INTO scores (Day, Model, Score) VALUES
('Day 1', 'A', 8.0),
('Day 2', 'A', 7.5),
('Day 3', 'A', 6.0),
('Day 4', 'A', 7.0),
('Day 1', 'B', 9.0),
('Day 2', 'B', 8.5),
('Day 3', 'B', 7.0),
('Day 4', 'B', 6.0),
('Day 1', 'C', 7.0),
('Day 2', 'C', 7.0),
('Day 3', 'C', 8.0),
('Day 4', 'C', 5.0);

-- 2. Chuyển dữ liệu thành dạng "long format"
SELECT 
    Day, 
    Model, 
    ROUND(Score, 0) AS Rounded_Score
INTO #long_format
FROM scores;

-- 3. Tạo bảng chéo (Contingency Table)
SELECT 
    Model, 
    Rounded_Score, 
    COUNT(*) AS Count
INTO #contingency_table
FROM #long_format
GROUP BY Model, Rounded_Score
ORDER BY Model, Rounded_Score;

-- 4. Hiển thị bảng chéo (Contingency Table)
SELECT * FROM #contingency_table;

-- 5. Tính tổng và giá trị kỳ vọng (Expected Values)
SELECT
    Model,
    Rounded_Score,
    Count,
    (SELECT SUM(Count) FROM #contingency_table) AS total,
    (SELECT SUM(Count) FROM #contingency_table WHERE Model = #contingency_table.Model) AS model_total,
    (SELECT SUM(Count) FROM #contingency_table WHERE Rounded_Score = #contingency_table.Rounded_Score) AS score_total,
    ((SELECT SUM(Count) FROM #contingency_table WHERE Model = #contingency_table.Model) * 
     (SELECT SUM(Count) FROM #contingency_table WHERE Rounded_Score = #contingency_table.Rounded_Score)) / 
    (SELECT SUM(Count) FROM #contingency_table) AS expected_value
INTO #expected_values
FROM #contingency_table;

-- 6. Tính thống kê Chi-squared
SELECT
    SUM((Count - expected_value) ^ 2 / expected_value) AS chi_squared_statistic
FROM #expected_values;

-- 7. Tính bậc tự do (Degrees of Freedom)
SELECT 
    (COUNT(DISTINCT Model) - 1) * (COUNT(DISTINCT Rounded_Score) - 1) AS degrees_of_freedom
FROM #contingency_table;

# Câu 3: Bảng flights(departure_time,…) chứa các giá trị thời gian dưới dạng số nguyên (ví dụ: 830 cho 8:30 AM, 1445 cho 2:45 PM). Hãy chuyển đổi các giá trị này thành định dạng thời gian.
-- 1. Tạo bảng chứa dữ liệu thời gian
CREATE TABLE departure_times (
    departure_time INT
);

-- 2. Chèn dữ liệu vào bảng
INSERT INTO departure_times (departure_time) VALUES
(830),
(1445),
(5),
(0),
(1230);

-- 3. Tạo cột mới để chứa thời gian đã chuyển đổi
ALTER TABLE departure_times
ADD departure_time_converted TIME;

-- 4. Cập nhật cột 'departure_time_converted' bằng cách chuyển đổi giá trị
UPDATE departure_times
SET departure_time_converted = 
    CASE
        WHEN departure_time BETWEEN 0 AND 2359 
        AND (departure_time % 100) < 60 
        THEN
            CAST(FLOOR(departure_time / 100) AS VARCHAR) + ':' + 
            RIGHT('00' + CAST(departure_time % 100 AS VARCHAR), 2)
        ELSE
            NULL
    END;

-- 5. Hiển thị kết quả
SELECT * FROM departure_times;

# Câu 4: Viết truy vấn SQL để tìm các ngoại lệ bằng cách sử dụng MAD. Một quy tắc chung là xem xét các giá trị ngoại lệ lớn hơn 1,5 lần so với giá trị MAD, trong đó x là số độ lệch chuẩn mà ta coi là có ý nghĩa.
DROP TABLE departure_times
-- 1. Tạo bảng chứa dữ liệu
CREATE TABLE departure_times (
    value INT
);

-- 2. Chèn dữ liệu vào bảng
INSERT INTO departure_times (value) VALUES
(10),
(12),
(11),
(13),
(12),
(90),
(11),
(10),
(13),
(14),
(100);

-- 3. Tính giá trị trung vị (Median)
WITH ordered_values AS (
    SELECT value,
           ROW_NUMBER() OVER (ORDER BY value) AS row_num,
           COUNT(*) OVER () AS total_count
    FROM departure_times
)
, median_value AS (
    SELECT value
    FROM ordered_values
    WHERE row_num = (total_count + 1) / 2
)
-- 4. Tính MAD (Độ lệch tuyệt đối trung bình)
, mad_value AS (
    SELECT AVG(ABS(dt.value - mv.value)) AS mad
    FROM departure_times dt
    CROSS JOIN median_value mv
)
-- 5. Đánh dấu ngoại lệ (Outlier)
SELECT 
    dt.value,
    CASE 
        WHEN ABS(dt.value - mv.value) > 1.5 * mv1.mad
        THEN 1
        ELSE 0
    END AS is_outlier
FROM departure_times dt
CROSS JOIN median_value mv
CROSS JOIN mad_value mv1;

# Câu 5: Hãy xác định liệu hai người trong bảng Patient(last_name, weight, height) có phải là một người hay không bằng cách sử dụng khoảng cách kết hợp Boolean trên “last_name” và “weight”.-- 1. Tạo bảng chứa dữ liệu bệnh nhân
CREATE TABLE Patients (
    patient_id INT PRIMARY KEY,
    last_name VARCHAR(100),
    weight INT,
    height INT
);

-- 2. Chèn dữ liệu vào bảng
INSERT INTO Patients (patient_id, last_name, weight, height) VALUES
(1, 'Nguyen', 60, 170),
(2, 'Nguyen', 60, 170),
(3, 'Tran', 65, 165),
(4, 'Le', 55, 160);

-- 3. Tìm các cặp bệnh nhân có last_name và weight giống nhau
SELECT p1.patient_id AS patient_1, p2.patient_id AS patient_2
FROM Patients p1
JOIN Patients p2
    ON p1.patient_id < p2.patient_id -- Điều kiện để tránh trùng lặp
    AND p1.last_name = p2.last_name -- So sánh last_name
    AND p1.weight = p2.weight; -- So sánh weight






