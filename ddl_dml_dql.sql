DROP DATABASE IF EXISTS `FECOM`;
CREATE DATABASE `FECOM`;
USE `FECOM`;

CREATE TABLE IF NOT EXISTS `Customer`(
 `CID`           int NOT NULL ,
 `FName`         varchar(25) NOT NULL ,
 `LName`         varchar(25) NOT NULL ,
 `DOB`           date NOT NULL,
 `Gender`        char(1) NOT NULL CHECK(`Gender`='M' or `Gender`='W'or `Gender`='O'),
 `Email`         varchar(100) NOT NULL ,
 `PhoneNo`       varchar(11) NOT NULL ,
 `HouseNo`       varchar(50) NOT NULL ,
 `StreetAddress` varchar(100) NOT NULL ,
 `City`          varchar(25) NOT NULL ,
 `State`         varchar(25) NOT NULL ,
 `Pincode`       int NOT NULL ,
 UNIQUE (`PhoneNo`),
 PRIMARY KEY (`CID`)
);

CREATE TABLE IF NOT EXISTS `Cart`(
 `CartID`   int NOT NULL CHECK(`CartID`<9999),
 `Quantity` int NOT NULL ,
 `Price`    int NOT NULL ,
 `CID`      int ,

PRIMARY KEY (`CartID`),
CONSTRAINT `FK_CID` FOREIGN KEY (`CID`) REFERENCES `Customer` (`CID`) ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS `Category`(
 `CateID`       int NOT NULL ,
 `Gender`       char(1) NOT NULL CHECK(`Gender`='M' or `Gender`='W' or `Gender`='O'),
 `CategoryName` varchar(25) NOT NULL ,

PRIMARY KEY (`CateID`)
);

CREATE TABLE IF NOT EXISTS `Product`(
 `ProductID`   int NOT NULL ,
 `ItemName`    varchar(100) NOT NULL ,
 `BrandName`   varchar(50) NOT NULL ,
 `Description` varchar(1500) NOT NULL ,
 `MRP`         int NOT NULL ,
 `Discount`    tinyint NOT NULL DEFAULT 0 ,
 `CateID`      int ,

PRIMARY KEY (`ProductID`),
CONSTRAINT `FK_CateID` FOREIGN KEY (`CateID`) REFERENCES `Category` (`CateID`) ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS `CPRelation`(
 `ProductID` int NOT NULL ,
 `CartID`    int NOT NULL ,

PRIMARY KEY (`ProductID`, `CartID`),
CONSTRAINT `FK_ProductID` FOREIGN KEY (`ProductID`) REFERENCES `Product` (`ProductID`) ON DELETE CASCADE ON UPDATE CASCADE,
CONSTRAINT `FK_CartID` FOREIGN KEY (`CartID`) REFERENCES `Cart` (`CartID`) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS `Order`(
 `OrderID` int NOT NULL ,
 `Status`  tinyint NOT NULL ,
 `CID`     int ,
 `CartID`  int ,

PRIMARY KEY (`OrderID`),
CONSTRAINT `FK_CID2` FOREIGN KEY (`CID`) REFERENCES `Customer` (`CID`) ON DELETE SET NULL ON UPDATE CASCADE,
CONSTRAINT `FK_CartID2` FOREIGN KEY (`CartID`) REFERENCES `Cart` (`CartID`) ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS `ProductImageSource`(
 `ImgSrc`    varchar(200) NOT NULL ,
 `ProductID` int NOT NULL ,

PRIMARY KEY (`ImgSrc`, `ProductID`),
CONSTRAINT `FK_ProductID2` FOREIGN KEY (`ProductID`) REFERENCES `Product` (`ProductID`) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS `Seller`(
 `SellerID`   int NOT NULL ,
 `SellerName` varchar(25) NOT NULL ,
 `Location`   varchar(50) NOT NULL ,

PRIMARY KEY (`SellerID`)
);

CREATE TABLE IF NOT EXISTS `SellRelation`(
 `SellerID`  int NOT NULL ,
 `ProductID` int NOT NULL ,
 `Size`      varchar(10) NOT NULL ,
 `Stock`     int NOT NULL ,

PRIMARY KEY (`SellerID`, `ProductID`),
CONSTRAINT `FK_ProductID3` FOREIGN KEY (`ProductID`) REFERENCES `Product` (`ProductID`) ON DELETE CASCADE ON UPDATE CASCADE,
CONSTRAINT `FK_SellerID` FOREIGN KEY (`SellerID`) REFERENCES `Seller` (`SellerID`) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS `Transaction`(
 `TransactionID` int NOT NULL ,
 `Status`        tinyint NOT NULL ,
 `OrderID`       int ,

PRIMARY KEY (`TransactionID`),
CONSTRAINT `FK_OrderID` FOREIGN KEY (`OrderID`) REFERENCES `Order` (`OrderID`) ON DELETE SET NULL ON UPDATE CASCADE
);

-- Check constraint for gender in Customer table
delimiter $$
create trigger TRI_CUST_GENDER before insert on `Customer`
for each row
begin
	if (new.`Gender` = 'm' or new.`Gender` = 'w' or new.`Gender` = 'o') then
		set new.`Gender` =  (ucase(new.`Gender`));
	elseif (new.`Gender` != 'M' or new.`Gender` != 'W' or new.`Gender` != 'O') then 
		signal sqlstate '45000' set message_text = 'gender must in [\'M\',\'F\',\'O\',\'m\',\'f\',\'o\']';
	end if;
end;$$

-- Check constraint for gender in Category table
delimiter $$
create trigger TRI_CATE_GENDER before insert on `Category`
for each row
begin
	if (new.`Gender` = 'm' or new.`Gender` = 'w' or new.`Gender` = 'o') then
		set new.`Gender` =  (ucase(new.`Gender`));
	elseif (new.`Gender` != 'M' or new.`Gender` != 'W' or new.`Gender` != 'O') then 
		signal sqlstate '45000' set message_text = 'gender must in [\'M\',\'F\',\'O\',\'m\',\'f\',\'o\']';
	end if;
end;$$

-- Check constraint for cart id as `Cart`.`CartID`>9999 ( -> which implies that the id must be of 4 digit)
delimiter $$
create trigger TRI_CART_ID before insert on `Cart`
for each row
begin
	if (new.`CartID` >9999) then
		signal sqlstate '45000' set message_text = 'max digit of ID is 4';
	end if;
end;$$

-- Cart Price and Quantity have to be updated before inserting a product into the cart
delimiter $$
create trigger TRI_CART_UPDATE after insert on `CPRelation`
for each row
begin
DECLARE tempint int;
DECLARE tempmrp int;
DECLARE realmrp int;
DECLARE tempdisco int;
set tempint := (select `Quantity` from `Cart` where new.`CartID`=`Cart`.`CartID`) + 1;
set realmrp := (select `Price` from `Cart` where new.`CartID`=`Cart`.`CartID`) ;
set tempmrp := (select `MRP` from `Product` where new.`ProductID`=`Product`.`ProductID`);
set tempdisco := (select `Discount` from `Product` where new.`ProductID`=`Product`.`ProductID`);
  UPDATE `Cart` SET `Quantity`= tempint where new.CartID = cart.CartID;
  UPDATE `Cart` SET Price = tempmrp where new.CartID = cart.CartID;
  UPDATE `Cart` SET `Price` = realmrp + (tempmrp - (tempmrp*tempdisco/100)) where new.CartID = cart.CartID;
end;$$

-- Cart Price and Quantity have to be updated before deleting a product from the cart
delimiter $$
create trigger TRI_CART_UPDATE2 before delete on `CPRelation`
for each row
begin
DECLARE tempint int;
DECLARE tempmrp int;
DECLARE realmrp int;
DECLARE tempdisco int;
set tempint := (select `Quantity` from `Cart` where old.`CartID`=`Cart`.`CartID`) - 1;
set realmrp := (select `Price` from `Cart` where old.`CartID`=`Cart`.`CartID`) ;
set tempmrp := (select `MRP` from `Product` where old.`ProductID`=`Product`.`ProductID`);
set tempdisco := (select `Discount` from `Product` where old.`ProductID`=`Product`.`ProductID`);
  UPDATE `Cart` SET `Quantity`= tempint where old.CartID = cart.CartID;
  UPDATE `Cart` SET Price = tempmrp where old.CartID = cart.CartID;
  UPDATE `Cart` SET `Price` = realmrp - (tempmrp - (tempmrp*tempdisco/100)) where old.CartID = cart.CartID;
end;$$

-- delimiter $$
-- create trigger TRI_CART_UPDATE3 before delete on `Product`
-- for each row
-- begin
-- DECLARE tempint int;
-- DECLARE tempmrp int;
-- DECLARE realmrp int;
-- DECLARE tempdisco int;
-- declare paisa int;
-- declare xyz int;

-- select `Quantity` into xyz from Cart where old.`ProductID`=`CPRelation`.`ProductID` and `CPRelation`.`CartID` = `Cart`.`CartID`;
-- set tempint := (select `Quantity` from `Cart` where old.`ProductID`=`Cart`.`ProductID`) - 1;
-- update Cart.`Quantity` set `Quantity` = tempint;

-- select `Price` into xyz from Cart where `CPRelation`.`ProductID` = old.`ProductID` and `CPRelation`.`CartID` = `Cart`.`CartID`;
-- set realmrp := (select `Price` from `Cart` where old.`ProductID`=`Cart`.`ProductID`) ;
-- set tempmrp := (select `MRP` from `Product` where old.`ProductID`=`Product`.`ProductID`);
-- set tempdisco := (select `Discount` from `Product` where old.`ProductID`=`Product`.`ProductID`);
-- set paisa := realmrp - (tempmrp - (tempmrp*tempdisco/100));
-- update Cart.`Price` set `Price` = tempint;

-- end;$$


-- delimiter $$
-- create trigger TRI_CART_UPDATE3 before delete on `Product`
-- for each row
-- begin
-- DECLARE tempint int;
-- DECLARE tempmrp int;
-- DECLARE realmrp int;
-- DECLARE tempdisco int;
-- declare paisa int;
-- declare xyz int;
-- update `Cart` set Quantity = Quantity -1
-- where `CartID` in(select distinct Cart.CartID from CPRelation join  Cart on (CPRelation.CartID = Cart.CartID and old.ProductID = CPRelation.ProductID));

-- -- select `Price` into xyz from Cart where `CPRelation`.`ProductID` = old.`ProductID` and `CPRelation`.`CartID` = `Cart`.`CartID`;
-- -- set realmrp := (select `Price` from `Cart` where old.`ProductID`=`Cart`.`ProductID`) ;
-- -- set tempmrp := (select `MRP` from `Product` where old.`ProductID`=`Product`.`ProductID`);
-- -- set tempdisco := (select `Discount` from `Product` where old.`ProductID`=`Product`.`ProductID`);
-- -- set paisa := realmrp - (tempmrp - (tempmrp*tempdisco/100));
-- -- update Cart set `Price` = tempint;

-- end;$$



insert into `Category` values
(8635, 'M', 'Casual Shoes'), 
(1880, 'W', 'Leggings'), 
(1750, 'W', 'Flip Flop & Slippers'), 
(9482, 'M', 'Tshirts'), 
(8236, 'M', 'Track Pants'), 
(7541, 'M', 'Casual Sandals'), 
(6754, 'M', 'Formal Shoes'), 
(1140, 'W', 'Sarees'), 
(5632, 'M', 'Socks'), 
(8494, 'M', 'Jackets & Coats'), 
(7425, 'M', 'Flip Flop & Slippers'), 
(2427, 'W', 'Salwars & Churidars'), 
(9208, 'W', 'Sweatshirt & Hoodies'), 
(5840, 'W', 'Heeled Shoes'), 
(7558, 'M', 'Backpacks'), 
(7624, 'W', 'Heeled Sandals'), 
(1234, 'W', 'Fusion Wear Sets'), 
(5646, 'W', 'Kurtas'), 
(6514, 'W', 'Sports Shoes'), 
(1622, 'W', 'Dupattas'), 
(1549, 'W', 'Shirts'), 
(4200, 'W', 'Tops'), 
(8407, 'W', 'Casual Shoes'), 
(4504, 'M', 'Jeans'), 
(3988, 'M', 'Kurtas'), 
(5581, 'M', 'Sports Shoes'), 
(8487, 'M', 'Sneakers'), 
(7127, 'M', 'Shirts'), 
(1182, 'M', 'Caps & Hats'), 
(7076, 'W', 'Track Pants');


INSERT INTO `Customer` VALUES
(9487 , 'Rita' , 'Barron' , '2003-09-30' , 'M' , 'ritabarron@wemail.com' , '8027797792' , '1300' , 'East Dowling Road' , 'Anchorage' , 'AK' , 99518),
(8014 , 'Elizabeth' , 'Saucedo' , '2016-06-22' , 'm' , 'elizabethsaucedo@wemail.com' , '7644815897' , '736' , 'Middle Turnpike East' , 'Manchester' , 'CT' , 06040),
(6219 , 'Amanda' , 'Smith' , '1997-05-06' , 'M' , 'amandasmith@wemail.com' , '9856296919' , '70' , 'Orchard Shore Road' , 'Colchester' , 'VT' , 05446),
(1512 , 'Jenny' , 'Davis' , '2006-09-16' , 'W' , 'jennydavis@wemail.com' , '7277506540' , '2306' , 'Edinburgh Drive' , 'Montgomery' , 'AL' , 36116),
(9236 , 'William' , 'Cowan' , '2010-03-11' , 'W' , 'williamcowan@wemail.com' , '8472166117' , '13583' , 'West 68th Avenue' , 'Arvada' , 'CO' , 80004),
(6921 , 'Lisa' , 'Black' , '1999-05-13' , 'm' , 'lisablack@wemail.com' , '8161673607' , '4385' , 'Wares Ferry Road' , 'Montgomery' , 'AL' , 36109),
(8547 , 'Jonathon' , 'Fenton' , '2009-03-10' , 'M' , 'jonathonfenton@wemail.com' , '7168108849' , '1601' , 'Northwest 22nd Street' , 'Oklahoma City' , 'OK' , 73106),
(3755 , 'Patrick' , 'Stogsdill' , '2011-06-06' , 'w' , 'patrickstogsdill@wemail.com' , '7962861613' , '42' , 'Lake Lane' , 'Westmore' , 'VT' , 05860),
(6273 , 'Dawn' , 'Degasparre' , '1993-08-14' , 'O' , 'dawndegasparre@wemail.com' , '7956592219' , '159' , 'Downey Drive' , 'Manchester' , 'CT' , 06040),
(3359 , 'Thomas' , 'Dion' , '2009-07-10' , 'M' , 'thomasdion@wemail.com' , '7785986255' , '210' , 'Beachcomber Drive' , 'Pismo Beach' , 'CA' , 93449),
(1679 , 'Stephen' , 'Schear' , '2007-12-20' , 'M' , 'stephenschear@wemail.com' , '8220692725' , '112' , 'Aquinnah Drive' , 'Pooler' , 'GA' , 31322),
(5272 , 'Curtis' , 'Creed' , '2000-09-03' , 'M' , 'curtiscreed@wemail.com' , '9719693451' , '7419' , 'West Hill Lane' , 'Glendale' , 'AZ' , 85310),
(3673 , 'Tammy' , 'Simpson' , '2018-12-04' , 'w' , 'tammysimpson@wemail.com' , '9020100216' , '10' , 'Bramblebush Drive' , 'Barnstable' , 'MA' , 02635),
(2476 , 'Crystal' , 'Storms' , '2019-06-21' , 'O' , 'crystalstorms@wemail.com' , '8205572032' , '6739' , 'Taft Court' , 'Arvada' , 'CO' , 80004),
(7308 , 'Charlie' , 'Nevarez' , '1997-11-19' , 'w' , 'charlienevarez@wemail.com' , '9111576422' , '5161' , 'Jefferson Boulevard' , 'Louisville' , 'KY' , 40219),
(8195 , 'Ricky' , 'Pierre' , '2019-02-28' , 'O' , 'rickypierre@wemail.com' , '9950948682' , '4121' , 'Northwest 31st Street' , 'Oklahoma City' , 'OK' , 73112),
(6062 , 'David' , 'Jablonski' , '1999-03-01' , 'O' , 'davidjablonski@wemail.com' , '8333698996' , '711' , 'Tatem Street' , 'Savannah' , 'GA' , 31405),
(3768 , 'Jeremy' , 'Highley' , '2008-12-30' , 'W' , 'jeremyhighley@wemail.com' , '7167130722' , '8505' , 'Waters Avenue' , 'Savannah' , 'GA' , 31406),
(6664 , 'Catherine' , 'Childers' , '2003-05-18' , 'O' , 'catherinechilders@wemail.com' , '7020056379' , '7102' , 'North 43rd Avenue' , 'Glendale' , 'AZ' , 85301),
(2977 , 'Lester' , 'Nielsen' , '2014-10-18' , 'O' , 'lesternielsen@wemail.com' , '8554777971' , '800' , 'West Street' , 'Panama City' , 'FL' , 32404),
(1377 , 'Christina' , 'Mcdermott' , '2019-01-18' , 'W' , 'christinamcdermott@wemail.com' , '9409551695' , '5224' , 'Wasena Avenue' , 'Baltimore' , 'MD' , 21225),
(6876 , 'Regina' , 'Garfield' , '1991-05-16' , 'W' , 'reginagarfield@wemail.com' , '8976482723' , '1478' , 'Sharps Point Road' , 'Annapolis' , 'MD' , 21409),
(8960 , 'John' , 'Mcmillin' , '2002-12-10' , 'O' , 'johnmcmillin@wemail.com' , '7070588069' , '5000' , 'V Street Northwest' , 'Washington' , 'DC' , 20007),
(5786 , 'Amy' , 'Kizer' , '2018-05-08' , 'm' , 'amykizer@wemail.com' , '7062960820' , '1263' , 'Evarts Street Northeast' , 'Washington' , 'DC' , 20018),
(4007 , 'Amelia' , 'Blackmon' , '2009-07-16' , 'w' , 'ameliablackmon@wemail.com' , '9763182998' , '4971' , 'Janet Court' , 'Livermore' , 'CA' , 94550);

INSERT INTO `Product` VALUES
(4695 , 'Lightly Distressed Skinny Jeans' , 'DNMX' , 'Logo placement;;5-pocket styling;;Cotton Blend;;Belt loops with button-loop closure;;Machine wash cold;;Low Rise;;' , 0 , 0, 4504),
(9356 , 'Washed Mid-Rise Jeans' , 'PEOPLE' , 'Machine wash;;75.5% Cotton, 23.5% Polyester, 1% Elastane;;Mid Rise;;' , 1699 , 50, 4504),
(9543 , 'Lightly Washed Joggers with Drawstring Fastening' , 'DNMX' , 'Whiskers;;5-pocket styling;;Cotton Blend;;Belt loops;;Stretchable fabric;;Machine wash;;Mid Rise;;' , 1499 , 49, 4504),
(2642 , 'Mid-Wash Slim Fit Jeans' , 'FLYING MACHINE' , '5-pocket styling;;100% Cotton;;Zip fly with pocket styling;;Machine wash;;Mid Rise;;' , 2199 , 59, 4504),
(4014 , 'Skinny Fit Jeans with Whiskers' , 'DNMX' , 'Zip fly button closure;;Belt loops;;Cotton Blend;;5-pocket styling;;Line dry;;Machine wash;;Mid Rise;;' , 1299 , 30, 4504),
(3839 , 'Lightly Washed Mid-Rise Slim Fit Jeans' , 'MUFTI' , 'Machine wash cold;;Mid Rise;;98% cotton, 2% elastane;;' , 2199 , 35, 4504),
(7175 , 'High-Neck Zip-Front Track Jacket' , 'PERFORMAX' , 'Regular Fit;;Moisture managed Quickdry technology;;Water-Resistant;;Insert pockets;;Polyester;;Transfer detail;;Performax technology and garment features vary from style to style;;Machine wash;;' , 1499 , 30, 8494),
(3521 , 'Colourblock Hooded Jacket with Zip-Insert Pockets' , 'AJIO' , 'Slim Fit;;Elasticated toggle fastening hems;;Polyester;;Machine wash;;' , 2999 , 59, 8494),
(3890 , 'High-Neck Zip-Front Track Jacket' , 'PERFORMAX' , 'Regular Fit;;Moisture managed Quickdry technology;;Water-Resistant;;Insert pockets;;Polyester;;Transfer detail;;Performax technology and garment features vary from style to style;;Machine wash;;' , 1499 , 30, 8494),
(1932 , 'High-Neck Zip-Front Track Jacket' , 'PERFORMAX' , 'Regular Fit;;Moisture managed Quickdry technology;;Water-Resistant;;Insert pockets;;Polyester;;Transfer detail;;Performax technology and garment features vary from style to style;;Machine wash;;' , 1499 , 30, 8494),
(4957 , 'Colourblock Slim Fit Zip-Front Hooded Jacket' , 'AJIO' , 'Slim Fit;;Polyester;;Machine wash;;' , 2499 , 54, 8494),
(8424 , 'Printed Zip-Front Reversible Jacket' , 'NETPLAY' , 'Tailored Fit;;Insert pockets;;Blended;;Dry clean;;' , 3499 , 59, 8494),
(4242 , 'Iridicent Reflective Zip-Front Hoodie' , 'PERFORMAX' , 'Hoodie with toggle fastening;;Thumb hole sleeves;;Polyester Blend;;Zip pocket;;Zipped chest pockets;;Machine wash;;Regular Fit;;360 reflective;;Hooded;;Running;;' , 1499 , 49, 8494),
(5863 , 'Checked Shirt with Patch Pocket' , 'PEOPLE' , 'Regular Fit;;100% Cotton;;Machine wash;;' , 1499 , 50, 7127),
(1659 , 'Striped Slim Fit Cotton Shirt' , 'THE INDIAN GARAGE CO' , 'Slim Fit;;Patch pocket;;100% Cotton;;Curved hemline;;Single-button square cuffs;;Machine wash;;' , 1749 , 75, 7127),
(7409 , 'Slim Fit Shirt with Patch Pocket' , 'NETWORK' , 'Slim Fit;;Single-button angled cuffs;;Cotton Blend;;Curved hemline;;Machine wash cold;;' , 0 , 0, 7127),
(3938 , 'Checked Shirt with Patch Pocket' , 'PEOPLE' , 'Regular Fit;;100% Cotton;;Machine wash;;' , 1499 , 50, 7127),
(9229 , 'Track Pants with Contrast Taping' , 'TEAMSPIRIT' , 'Side insert pockets;;Cotton Blend;;Line dry;;Machine wash;;' , 499 , 10, 8236),
(2081 , 'Joggers with Insert Pockets' , 'PERFORMAX' , 'Elasticated waist with drawcod;;100% polyester;;' , 899 , 40, 8236),
(3454 , 'Joggers with Insert Pockets' , 'PERFORMAX' , 'Elasticated waist with drawcod;;100% polyester;;' , 899 , 40, 8236),
(3640 , 'Track Pants with Contrast Taping' , 'TEAMSPIRIT' , 'Side insert pockets;;Cotton Blend;;Line dry;;Machine wash;;' , 499 , 10, 8236),
(4036 , 'Heathered Track Pants with Contrast Taping' , 'TEAMSPIRIT' , 'Side insert pockets;;Cotton Blend;;Line dry;;Machine wash;;' , 499 , 10, 8236),
(3529 , 'Typographic Print Crew-Neck T-shirt' , 'DNMX' , 'Regular Fit;;Contrast taping along the shoulders;;100% Cotton;;Raglan sleeves;;Machine wash;;' , 0 , 0, 9482),
(6508 , 'Typographic Print Crew-Neck T-shirt' , 'DNMX' , 'Regular Fit;;100% Cotton;;Machine wash cold;;' , 0 , 0, 9482),
(9428 , 'Colourblock Crew-Neck T-shirt with Patch Pocket' , 'TEAMSPIRIT' , 'Regular Fit;;Cotton Blend;;Machine wash;;' , 0 , 0, 9482),
(1484 , 'Polo T-shirt with Ribbed Hems' , 'NETPLAY' , 'Regular Fit;;Vented hemline;;Embroidered logo;;Machine wash cold;;65% cotton, 35% polyester;;' , 0 , 0, 9482),
(1970 , 'Striped Polo T-shirt with Ribbed Hems' , 'NETPLAY' , 'Regular Fit;;Vented hemline;;Machine wash cold;;65% cotton, 35% polyester;;' , 0 , 0, 9482),
(2017 , 'Bijor Dobby Cotton Kurta with Full Sleeves' , 'INDIE PICKS' , 'Regular Fit;;Short button placket;;Bijnor cotton fabrics are woven on dobbies and have unique textures;;100% Cotton;;Front patch pocket, side insert pockets;;Hand wash cold separately;;' , 1499 , 59, 3988),
(6709 , 'Handblock Print Kalamkari Cotton Long Kurta' , 'INDIE PICKS' , 'Regular Fit;;Characteristic imperfections associated with handblock printing may be observed. Colours may fade or bleed due to the traditional dyeing and printing process employed.;;Kalamkari is a traditional handblock printing technique practised in the Machilipatnam cluster of Andhra Pradesh;;Side slits and pockets;;100% Cotton;;Half-button placket;;Hand wash separately in cold water. Use mild detergent.;;' , 2499 , 59, 3988),
(1792 , 'Handblock Print Kalamkari Cotton Long Kurta' , 'INDIE PICKS' , 'Regular Fit;;Short button placket;;Side pockets;;100% Cotton;;Side slits;;Kalamkari is a traditional handblock printing technique practiced in the Machhilipatnam cluster of Andhra Pradesh;;Characteristic imperfections associated with hand block printing may be observed, and colours may fade or bleed due to the traditional dyeing and printing process employed;;Hand wash cold separately;;' , 2499 , 59, 3988),
(3073 , 'Short Kurta with Mandarin Collar' , 'VIVID INDIA' , 'Regular Fit;;Vented sides;;100% Cotton;;Short button placket;;Hand wash cold separately;;' , 0 , 0, 3988),
(5355 , 'Handblock Print Kalamkari Cotton Long Kurta' , 'INDIE PICKS' , 'Regular Fit;;Side slits;;Short button placket;;100% Cotton;;Side pockets;;Kalamkari is a traditional handblock printing technique practiced in the Machhilipatnam cluster of Andhra Pradesh;;Characteristic imperfections associated with handblock printing may be observed, and colours may fade or bleed due to the traditional dyeing and printing process employed;;Hand wash cold separately;;' , 2499 , 59, 3988),
(4032 , 'Embroidered Short Kurta' , 'VIVID INDIA' , 'Regular Fit;;Side slits;;100% Cotton;;Notched placket;;Hand wash cold separately;;' , 0 , 0, 3988),
(5617 , 'Colourblock Rucksack Backpack' , 'CHRIS & KATE' , 'Polyester;;Bottom depth: 6.3 inches (16 cm);;Bottom width: 11.4 inches (29 cm);;3-month warranty against manufacturing defects;;Height: 17.7 inches (45 cm);;Wipe with clean, dry cloth;;' , 2499 , 74, 7558),
(2022 , 'Laptop Backpack with Adjustable Shoulder Straps ' , 'PUMA' , 'Polyester;;Store in a clean and dry environment, avoid contact with water & perfume;;' , 3499 , 35, 7558),
(3577 , 'Pack of 5 Ankle-Length Socks' , 'MARC' , 'Pack of 5;;70% cotton, 4% spandex, 26% nylon;;' , 599 , 49, 5632),
(7536 , 'Pack of 2 Snow Merino Socks' , 'SUPERDRY' , 'Pack of 2;;Machine wash cold;;78% acrylic, 21% polyamide, 1% elastane;;' , 2599 , 20, 5632),
(6290 , 'Baseball Cap with Logo Branding' , 'PUMA' , 'Polyester;;Hand wash warm;;' , 1299 , 49, 1182),
(5715 , 'Baseball Cap with Branding' , 'PUMA' , 'Polyester;;Hand wash warm;;' , 1299 , 49, 1182),
(5952 , 'UP Lace-Up Casual Shoes' , 'PUMA' , 'Synthetic upper;;PUMA No. 2 Logo at sole;;Inject your look with new energy in our PUMA UP. We took cues from previous street favourites to bring you this fresh take on classic street attitude. This trainer features a synthetic leather upper with exaggerated branding and the iconic PUMA Formstrip to cap off a look that is authentically PUMA.;;PUMA No. 2 Logo at lateral side;;Lace Fastening;;Synthetic leather upper; Rubber midsole; Rubber outsole;;PUMA No. 1 Logo at tongue;;Rubber sole;;PUMA Formstrip at lateral side;;Wipe with a clean, dry cloth when needed;;' , 3999 , 49, 8635),
(2006 , 'Slip-On Casual Shoes' , 'CHRISTOFANO' , 'Mesh upper;;Pull tabs;;Slip-on Styling;;PVC sole;;Avoid contact with water;;' , 799 , 20, 8635),
(8502 , 'Genuine Leather Thong-Strap Flip-Flops' , 'STEVE MADDEN' , 'Genuine leather upper;;Adjustable buckle closure along the strap;;TPR sole;;Wipe with a clean, dry cloth when needed;;' , 7999 , 30, 7425),
(2961 , 'Premium Beach Sliders' , 'SUPERDRY' , 'PU upper;;Regular Fit;;Signature branding;;TPR sole;;Wipe with a clean, dry cloth when needed;;' , 0 , 0, 7425),
(4867 , 'Lace-Up Ankle Boots' , 'LEE COOPER' , 'Leather upper;;1-month warranty against manufacturing defects;;Lace Fastening;;TPR sole;;Wipe with a clean, dry cloth when needed;;' , 2999 , 27, 6754),
(9222 , 'Almond-Toe Lace-Up Derby Shoes' , 'JOE SHU' , 'Genuine leather upper;;Leather insole;;Lace Fastening;;Rubber sole;;' , 13990 , 10, 6754),
(9936 , 'Slip-On Casual Sandals' , 'PUMA' , 'PU upper;;3-month warranty against manufacturing defects;;Velcro Fastening;;Rubber sole;;Wipe with a clean, dry cloth when needed;;' , 1999 , 49, 7541),
(2260 , 'Open-Toe Sliders with Branding' , 'CROCS' , '3-month warranty against manufacturing defects;;We recommend you buy a size smaller;;Solid;;EVA sole & upper;;Wipe with a clean, dry cloth when needed;;' , 1295 , 34, 1750),
(1651 , 'Depth Charge 2.0 Colourblock Slip-On Sneakers' , 'SKECHERS' , '3-month warranty against manufacturing defects;;Slip-on Styling;;Mesh and synthetic upper;;Pull tabs;;EVA sole;;Wipe with a clean, dry cloth when needed;;' , 4499 , 40, 8487),
(1146 , 'Textured Low-Top Lace-Up Sneakers' , 'UNITED COLORS OF BENETTON' , 'PU upper;;Regular Fit;;3-month warranty against manufacturing defects;;Lace Fastening;;Panelled construction;;Rubber sole;;Wipe with a clean, dry cloth when needed;;' , 3199 , 50, 8487),
(7320 , 'LQDCELL Tension Training Sports Shoes' , 'PUMA' , 'Synthetic upper;;3-month warranty against manufacturing defects;;Lace Fastening;;Rubber sole;;Wipe with a clean, dry cloth when needed;;' , 7999 , 40, 5581),
(6480 , 'Todos Panelled Lace-Up Sports Shoes' , 'NIKE' , 'Synthetic upper;;Padded heel collar; pull-up tabs;;6-month warranty against manufacturing defects (not valid on more than 20% discounted products);;Lace Fastening;;Rubber sole;;Perforated upper;;Wipe with a clean, dry cloth when needed;;' , 3995 , 29, 5581),
(9146 , 'Floral Print Straight Kurta with Notched Neckline' , 'AVAASA MIX N\' MATCH' , 'Vented hemlines;;Roll-up tabs;;Rayon;;Short button placket;;No Darts;;Machine wash;;' , 0 , 0, 5646),
(8374 , 'Floral Print Straight Kurta' , 'AVAASA MIX N\' MATCH' , '100% Cotton;;No Darts;;Machine wash;;' , 0 , 0, 5646),
(7415 , 'Churidar Leggings with Elasticated Waistband' , 'AVAASA MIX N\' MATCH' , 'Crafted from cotton and tailored with an elasticated waistband for a comfortable, customised fit, this pair of churidar leggings is the most versatile accompaniment for modern ethnic ensembles;;100% cotton;;Machine wash;;' , 399 , 15, 2427),
(2353 , 'Churidar Leggings with Elasticated Waistband' , 'AVAASA MIX N\' MATCH' , 'Crafted from cotton and tailored with an elasticated waistband for a comfortable, customised fit, this pair of churidar leggings is the most versatile accompaniment for modern ethnic ensembles;;Machine wash;;100% cotton;;' , 399 , 15, 2427),
(7000 , 'Churidar Leggings with Elasticated Waistband' , 'AVAASA MIX N\' MATCH' , 'Crafted from cotton and tailored with an elasticated waistband for a comfortable, customised fit, this pair of churidar leggings is the most versatile accompaniment for modern ethnic ensembles;;100% cotton;;Machine wash;;' , 399 , 15, 2427),
(7681 , 'Handblock Print Jaipuri Pure Chanderi Saree' , 'INDIE PICKS' , 'Saree length: 6.3 m; Saree width: 1 m;;Blouse length: 0.8 m;;Hand block printing is a centuries old art form that utilizes a hand carved wood block, dipped in dye and stamped by hand onto fabric.;;Cotton Silk;;Characteristic imperfections associated with hand block printing may be observed, and colours may fade or bleed due to the traditional dyeing and printing process employed.;;Dry clean;;' , 5999 , 49, 1140),
(6625 , 'Printed Saree with Tassels' , 'VANMAYI' , 'Saree length: 5.5 m;;50% cotton, 50% polyester;;Dry clean;;' , 3602 , 74, 1140),
(5199 , 'Kutch Hand Bandhani Banarasi Silk Zari Saree' , 'INDIE PICKS' , 'Banarasi sarees are characterised by  brocade borders & pallus. They often have woven butas or jaal on the body.;;Saree length: 5.5 m;;Bandhani technique involves dyeing a fabric which is tied tightly with a thread at several points, thus producing a variety of patterns.;;Art Silk;;Characteristic imperfections associated with hand tie dyeing may be observed, and colours may fade or bleed due to the traditional dyeing process employed.;;Hand wash cold separately;;' , 3999 , 69, 1140),
(2706 , 'Textured Dupatta with Tassels' , 'AURELIA' , 'Dupatta length: 2.35 m;;Cotton Blend;;Machine wash;;' , 499 , 40, 1622),
(1366 , 'Crushed Dupatta with Beaded Hems' , 'AVAASA MIX N\' MATCH' , 'Length: 2.35 m;;Polyester Blend;;Machine wash;;' , 299 , 49, 1622),
(7967 , 'Kota Doria Cotton Dupatta with Zari' , 'AVAASA MIX N\' MATCH' , 'Length: 2.25 m;;Width: 0.85 m;;Machine wash;;Cotton blend;;' , 0 , 0, 1622),
(4586 , 'Capris with Insert Pockets' , 'TEAMSPIRIT' , 'Cotton Blend;;Elasticated drawstring wasit;;Universal;;Machine wash cold;;' , 499 , 10, 1880),
(8699 , 'High-Rise Treggings with Zip Closure' , 'RIO' , 'Cotton Blend;;Machine wash;;' , 999 , 49, 1880),
(6978 , 'Evoke Colourblock Training Leggings' , 'PERFORMAX' , 'Ergonomic flatlock seams deliver a comfortable, chafe-free fit;;Elasticated waistband;;Polyester;;R|Elan™ Kooltex Special finish keeps the wearer cool, dry and comfortable by inherent moisture management technology.It\'s Unique Capillary structure transports sweat through micro-channels to fabric outer surface, spreads it over a larger area and helps evaporate swiftly creating a cooling effect.;;Elasticated waist;;Gym;;Machine wash;;' , 999 , 30, 1880),
(2986 , 'Typographic Print Joggers with Insert Pockets' , 'TEAMSPIRIT' , 'Elasticated waistband with drawstring fastening;;100% Cotton;;Machine wash cold;;' , 0 , 0, 7076),
(9096 , 'Trackpants with Elasticated Waistband' , 'TEAMSPIRIT' , 'Drawstring fastening;;The relaxed fit of these track pants with contrast taping ensures comfort without compromising on style;;Cotton Blend;;Machine wash;;' , 399 , 15, 7076),
(8798 , 'Track Pants with Drawstring Waist' , 'TEAMSPIRIT' , 'Blended;;Machine wash cold;;' , 699 , 15, 7076),
(5563 , 'Floral Print Shirt Top' , 'AJIO' , 'Curved hemline;;100% Cotton;;Banded cuffs;;Machine wash cold;;' , 999 , 30, 1549),
(1631 , 'Checked Slim Shirt with Tulip Sleeves' , 'DNMX' , 'Machine wash cold;;100% rayon;;' , 0 , 0, 1549),
(5474 , 'Checked Shirt with Patch Pocket' , 'DNMX' , 'Roll-up tabs;;Rayon;;Machine wash;;' , 699 , 5, 1549),
(2318 , ' Novelty  Top ' , 'PANNKH' , 'Relaxed Fit;;Hand wash;;' , 999 , 45, 4200),
(5159 , 'Round-Neck Top with Lace Insets' , 'PROJECT EVE WW WORK' , 'Flared sleeve hems;;Cut out;;Project Eve apparel is tailored keeping movement and comfort in mind. Here\'s a suggestion : Pick a size smaller than your normal size to make sure our fashion fits you perfectly.;;Relaxed Fit;;Machine wash;;100% polyester;;' , 1999 , 69, 4200),
(1611 , ' Solid  Top ' , 'RIGO' , 'Blended;;Relaxed Fit;;Machine wash;;' , 799 , 54, 4200),
(3931 , 'Typographic Print Crew-Neck Sweatshirt' , 'DNMX' , '100% Cotton;;Machine wash cold;;' , 499 , 10, 9208),
(7355 , 'Crew-Neck Sweatshirt with Numeric Applique' , 'DNMX' , '100% Cotton;;Machine wash cold;;' , 499 , 10, 9208),
(1829 , 'Printed Crew-Neck Sweatshirt' , 'DNMX' , '100% Cotton;;Machine wash cold;;' , 499 , 10, 9208),
(9732 , 'Floral Print Straight Kurta with Striped Palazzos' , 'JAIPUR KURTI' , 'Button accents along the yoke;;Notched collar;;Poly voile;;Machine wash;;' , 3299 , 59, 1234),
(5284 , 'Block Print Skirt-Suit Set' , 'MABISH BY SONAL JAIN' , 'Dry clean;;' , 2999 , 40, 1234),
(4991 , 'Embroidered Straight Kurta with Pants' , 'JAIPUR KURTI' , 'Kurta with side slits and mirror work;;Pants with semi-elasticated waist and slip pockets;;Machine wash;;Rayon slub;;' , 2549 , 65, 1234),
(9461 , 'Slip-On Shoes with Mesh Panel' , 'HI-ATTITUDE' , 'Synthetic upper;;Pull-up tabs;;PVC sole;;Wipe with a clean, dry cloth when needed;;' , 699 , 20, 8407),
(6918 , 'Embellished Slip-On Casual Shoes' , 'HI-ATTITUDE' , 'Synthetic upper;;PVC sole;;Wipe with a clean, dry cloth when needed;;' , 799 , 20, 8407),
(1291 , 'Washable Lace-Up Performance Shoes' , 'PERFORMAX' , 'Synthetic upper;;Pull-up tabs;;White;;Hand wash;;EVA sole;;' , 1799 , 50, 6514),
(2451 , 'Textured Lace-Up Sports Shoes' , 'NIKE' , 'Synthetic upper;;Grey;;Cushioned heel collar;;Rubber sole;;Wipe with a clean, dry cloth when needed;;' , 3695 , 40, 6514),
(7664 , 'Downshifter 9 Lace-Up Running Shoes' , 'NIKE' , 'Synthetic upper;;Signature branding;;6-month warranty against manufacturing defects (not valid on more than 20% discounted products);;Grey;;Mesh panel;;Midsole cushioning, flex grooves;;Rubber sole;;Wipe with a clean, dry cloth when needed;;' , 3995 , 38, 6514),
(1879 , 'Strappy Heeled Sandals with Buckle Closure' , 'HI-ATTITUDE' , 'Synthetic upper;;Regular Fit;;Heel height: 1.25 inches;;PVC sole;;Wipe with a clean, dry cloth when needed;;' , 699 , 20, 7624),
(7812 , 'Peep-Toe Ankle-Length Cone Heeled Sandals' , 'CATWALK' , 'Synthetic upper;;PU insole;;Narrow Fit;;Elasticated gussets;;Wipe with a clean, dry cloth when needed;;' , 1895 , 69, 7624),
(1902 , 'Embellished Ankle-Strap Chunky Heels' , 'CATWALK' , 'Synthetic upper;;Heel height: 4 inches;;PU sole;;Wipe with a clean, dry cloth when needed;;' , 2495 , 63, 7624),
(8144 , 'Strappy Wedges with Buckle Closure' , 'MARC LOIRE' , 'Faux leather upper;;Heel height: 1. 3 inches;;Resin sole;;Wipe with a clean, dry cloth when needed;;' , 1899 , 62, 7624),
(3131 , 'Alexxa Pointed-Toe Heeled Court Shoes' , 'DUNE LONDON' , 'Synthetic upper;;Synthetic sole and insole;;Regular Fit;;Heel height: 3.5 inches (9 cm);;Wipe with a clean, dry cloth when needed;;' , 3999 , 49, 7624),
(2808 , 'Animal Print Slip-On Heeled Shoes' , 'CATWALK' , 'PU upper;;Animal;;Heel height: 3 inches;;TPR sole;;Wipe with a clean, dry cloth when needed;;' , 2495 , 69, 5840),
(7264 , 'Duchess Embellished Slingback Stilettos' , 'DUNE LONDON' , 'Synthetic upper;;PU insole;;Regular Fit;;Embellished;;Buckle closure;;PU sole;;Wipe with a clean, dry cloth when needed;;' , 9999 , 30, 5840),
(2966 , 'Pointed-Toe Slingback Chunky Heeled Shoes' , 'AJIO' , 'PU upper;;Mid-foot strap with buckle closure;;Regular Fit;;Heel height: 2.25 inches;;Rubber sole, insole;;Wipe with a clean, dry cloth when needed;;' , 2999 , 79, 5840);


INSERT INTO `ProductImageSource` VALUES
('https://assets.ajio.com/medias/sys_master/root/h8d/h1f/16496021209118/-78Wx98H-441025044-tintblue-MODEL3.jpg' , 4695),
('https://assets.ajio.com/medias/sys_master/root/hbd/h27/16496024125470/-78Wx98H-441025044-tintblue-MODEL4.jpg' , 4695),
('https://assets.ajio.com/medias/sys_master/root/h28/h76/16496017965086/-78Wx98H-441025044-tintblue-MODEL2.jpg' , 4695),
('https://assets.ajio.com/medias/sys_master/root/hff/hac/16496030089246/-78Wx98H-441025044-tintblue-MODEL.jpg' , 4695),
('https://assets.ajio.com/medias/sys_master/root/h87/hdc/16496028909598/-473Wx593H-441025044-tintblue-MODEL.jpg' , 4695),
('https://assets.ajio.com/medias/sys_master/root/hc3/h82/14270494146590/-78Wx98H-460482018-blue-MODEL5.jpg' , 9356),
('https://assets.ajio.com/medias/sys_master/root/h04/h8d/14270488641566/-78Wx98H-460482018-blue-MODEL4.jpg' , 9356),
('https://assets.ajio.com/medias/sys_master/root/hef/hbf/14270497062942/-473Wx593H-460482018-blue-MODEL.jpg' , 9356),
('https://assets.ajio.com/medias/sys_master/root/hd5/hbe/14270508498974/-78Wx98H-460482018-blue-MODEL3.jpg' , 9356),
('https://assets.ajio.com/medias/sys_master/root/h98/hdf/14270498078750/-78Wx98H-460482018-blue-MODEL.jpg' , 9356),
('https://assets.ajio.com/medias/sys_master/root/hdf/ha5/14270491459614/-78Wx98H-460482018-blue-MODEL2.jpg' , 9356),
('https://assets.ajio.com/medias/sys_master/root/hf5/h5d/15129320751134/-78Wx98H-441012518-black-MODEL3.jpg' , 9543),
('https://assets.ajio.com/medias/sys_master/root/h6b/h78/15129315639326/-78Wx98H-441012518-black-MODEL2.jpg' , 9543),
('https://assets.ajio.com/medias/sys_master/root/h70/hc5/15129326977054/-78Wx98H-441012518-black-MODEL.jpg' , 9543),
('https://assets.ajio.com/medias/sys_master/root/h41/hba/15129325338654/-473Wx593H-441012518-black-MODEL.jpg' , 9543),
('https://assets.ajio.com/medias/sys_master/root/he1/h19/15129317998622/-78Wx98H-441012518-black-MODEL4.jpg' , 9543);


INSERT INTO `Seller` VALUES
(8122, 'Appario Retail' , 'CO'),
(8264, 'Cloudtail' , 'AL'),
(6406, 'STPL' , 'MD'),
(3954, 'Electrama' , 'FL'),
(2928, 'Darshita' , 'AZ'),
(2807, 'BasicDeal' , 'OK'),
(4496, 'weguarantee' , 'VT');

INSERT INTO SellRelation VALUES
(4496, 5952, '36' ,19),
(2807, 8798, '38' ,32),
(2928, 3931, '37' ,45),
(3954, 7415, '37' ,8),
(2928, 9936, '36' ,13),
(8122, 9229, '36' ,31),
(8122, 2451, '38' ,5),
(3954, 8502, '38' ,38),
(4496, 8502, '39' ,26),
(3954, 1651, '38' ,12),
(6406, 2081, '37' ,46),
(8122, 9543, '38' ,30),
(8122, 1631, '39' ,43),
(2928, 2353, '39' ,49),
(8264, 2961, '37' ,16),
(8122, 2260, '36' ,22),
(2807, 3131, '40' ,35),
(2807, 9732, '41' ,48),
(2928, 9222, '37' ,13),
(8264, 3521, '39' ,30);

insert into Cart values
(4155, 0, 0,7308),
(4152, 0, 0,7308),
(7028, 0, 0,3755),
(9880, 0, 0,8014),
(5685, 0, 0,6062),
(5345, 0, 0,6062),
(6994, 0, 0,7308),
(6919, 0, 0,6921),
(9627, 0, 0,6921),
(4309, 0, 0,1512),
(4478, 0, 0,5786);


-- SET SQL_SAFE_UPDATES = 0;-- 
insert into CPRelation values
(3521, 4309),
(4695, 5345),
(3890, 9627),
(4695, 6919),
(3521, 9627),
(1932, 4309),
(9356, 4152),
(3890, 4152),
(9356, 7028),
(7175, 6919),
(9543, 5345),
(2642, 4309),
(4014, 5345),
(4014, 4152),
(3521, 5685),
(2642, 9627),
(3890, 6994),
(4695, 4152);

insert into `Order` values
(4367, 1 , 8547, 4152),
(8507, 0 , 5786, 7028),
(3691, 1 , 3359, 4309),
(7033, 0 , 6876, 9627),
(8699, 1 , 6273, 5345),
(6660, 1 , 3359, 4478),
(3672, 1 , 3673, 6919);

insert into `Transaction` values
(1000, 1 , 3672),
(1001, 0 , 6660),
(1002, 0 , 3691),
(1003, 1 , 7033),
(1004, 0 , 4367),
(1005, 1 , 8507);

DELETE FROM `Product` WHERE `Product`.`ProductID` = 3890;




SELECT * FROM CUSTOMER;
select * from PRODUCT;
select * from CATEGORY;
select * from ProductImageSource;
select * from Seller;
select * from SellRelation;
select * from Cart;
select * from CPRelation;
select * from `Order`;
select * from `Transaction`;


-- List the customers and their cart details whose cart either contains at least two items or is worth more than Rs.1500
select CID, FName, LName, Price, Quantity from Customer natural join 
(	( 	SELECT * FROM Cart GROUP BY CartID HAVING SUM(Price)>1500)	union 
	(	SELECT * FROM Cart GROUP BY CartID HAVING SUM(Quantity)>2 or SUM(Quantity)=2)
) as a1;

-- Some of the customers got the delivered item, but never paid for it. List the customer's details with his/her phone number, orderID, transactionID, cartID and the price which they owe.
select e2.TransactionID, e2.OrderID,e2.CID, e2.CartID, e2.Quantity, e2.Price, cus.FName, cus.LName, cus.PhoneNo from Customer as cus inner join
(	select e1.TransactionID, e1.OrderID,e1.CID, e1.CartID, cca.Quantity, cca.Price from Cart as cca inner join 
	(	select t.TransactionID, t.OrderID,o.CID, o.CartID  from `Transaction` as t inner join `Order`as o on t.OrderID = o.OrderID where t.`Status` = 0 and o.`Status`=1
    ) as e1 where cca.CartID = e1.CartID and Quantity !=0
) 	as e2 where e2.CID = cus.CID;

-- List out the products with the number of images available [only if the number is not zero].
select p.ProductID, p.ItemName, p.BrandName, kk.CountImages from Product as p join
(	select count(*) as CountImages, ProductID from ProductImageSource as pis group by ProductID
) as kk
where kk.ProductID = p.ProductID;

-- Get the most priced product in the catalog.
select max(MRP), ProductID, BrandName, ItemName from Product;

-- Get the 10 most priced product in the catalog
select ProductID, BrandName, ItemName, MRP from Product order by (MRP - (MRP*Discount)/100) desc limit 10;

-- List out all the customers with all oof their carts
(select * from Customer left outer join Cart on Customer.CID = Cart.CID )
union
(select * from Customer right outer join Cart on Customer.CID = Cart.CID )

