-- Insert pack
INSERT INTO PackData (packid, packname, author, contact)
VALUES ('norinco_ground', 'Norinco Ground', 'Len', 'lengthened_gradient');

-- Insert dupes using the string packid
INSERT INTO DupeData (path, name, cost, weight, type, packid) VALUES
('aa20', 'AA20', 71.53, 9062, 'AA', 'norinco_ground'),
('apc12', 'APC12', 41.29, 6970.96, 'APC', 'norinco_ground'),
('atm152', 'ATM152', 61.86, 7951.07, 'ATGM', 'norinco_ground'),
('ifv10030', 'IFV-10030', 269.83, 24273.29, 'IFV', 'norinco_ground'),
('lt85', 'LT-85', 91.78, 9163.5, 'Light Tank', 'norinco_ground'),
('spg152', 'SPG-152', 204.89, 13454.17, 'SPG', 'norinco_ground'),
('wcv105', 'WCV-105', 187.58, 18354.13, 'Light Tank', 'norinco_ground'),
('wfv25', 'WFV-25', 136.55, 13145.43, 'IFV', 'norinco_ground'),
('wpv12', 'WPV-12', 22.48, 3066.14, 'Transport', 'norinco_ground'),
('wtv12', 'WTV-12', 46.52, 9397.84, 'Transport', 'norinco_ground');