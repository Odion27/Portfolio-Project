---Nashville Housing Data Cleaning

SELECT * FROM [Nashville Housing];

--Standardize Date Format
ALTER TABLE [Nashville Housing]
ADD SalesDateConverted DATE;

UPDATE [Nashville Housing]
SET SalesDateConverted = CAST(SaleDate AS DATE);

--Organize Property Address data
--Find records with NULL PropertyAddress
SELECT PropertyAddress 
FROM [Nashville Housing]
WHERE PropertyAddress IS NULL;

SELECT * 
FROM [Nashville Housing]
WHERE PropertyAddress IS NULL;

--Identify and update NULL PropertyAddress records
SELECT X.UniqueID, X.ParcelID, X.PropertyAddress, Y.UniqueID, Y.ParcelID, Y.PropertyAddress  
FROM [Nashville Housing] X
JOIN [Nashville Housing] Y
ON X.ParcelID = Y.ParcelID
AND X.UniqueID <> Y.UniqueID
WHERE X.PropertyAddress IS NULL;

UPDATE X
SET X.PropertyAddress = ISNULL(X.PropertyAddress, Y.PropertyAddress)
FROM [Nashville Housing] X
JOIN [Nashville Housing] Y
ON X.ParcelID = Y.ParcelID
AND X.UniqueID <> Y.UniqueID
WHERE X.PropertyAddress IS NULL;

--Break out Address into individual columns (Address, City, and State)
--Split PropertyAddress
ALTER TABLE [Nashville Housing]
ADD PropertySplitAddress NVARCHAR(255),
    PropertyAddressCity NVARCHAR(255);

UPDATE [Nashville Housing]
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1),
    PropertyAddressCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress));

--Split OwnerAddress
ALTER TABLE [Nashville Housing]
ADD OwnerSplitAddress NVARCHAR(255),
    OwnerAddressCity NVARCHAR(255),
    OwnerAddressState NVARCHAR(255);

UPDATE [Nashville Housing]
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
    OwnerAddressCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
    OwnerAddressState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);

--Rename columns
EXEC sp_rename '[Nashville Housing].OwnerAddressCity', 'OwnerSplitCity', 'COLUMN';
EXEC sp_rename '[Nashville Housing].OwnerAddressState', 'OwnerSplitState', 'COLUMN';

--Change Y and N to Yes and No in SoldAsVacant column
UPDATE [Nashville Housing]
SET SoldAsVacant = CASE 
    WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant 
END;

-- Remove duplicates and store them in Temp Table
--Create Temp Table
CREATE TABLE [#Nashville Housing](
   	[UniqueID ] [float] NULL,
	[ParcelID] [nvarchar](255) NULL,
	[LandUse] [nvarchar](255) NULL,
	[PropertyAddress] [nvarchar](255) NULL,
	[SaleDate] [datetime] NULL,
	[SalePrice] [float] NULL,
	[LegalReference] [nvarchar](255) NULL,
	[SoldAsVacant] [nvarchar](255) NULL,
	[OwnerName] [nvarchar](255) NULL,
	[OwnerAddress] [nvarchar](255) NULL,
	[Acreage] [float] NULL,
	[TaxDistrict] [nvarchar](255) NULL,
	[LandValue] [float] NULL,
	[BuildingValue] [float] NULL,
	[TotalValue] [float] NULL,
	[YearBuilt] [float] NULL,
	[Bedrooms] [float] NULL,
	[FullBath] [float] NULL,
	[HalfBath] [float] NULL,
	[SalesDateConverted] [date] NULL,
	[PropertySplitAddress] [nvarchar](255) NULL,
	[PropertyAddressCity] [nvarchar](255) NULL,
	[OwnerSplitAddress] [nvarchar](255) NULL,
	[OwnerSplitCity] [nvarchar](255) NULL,
	[OwnerSplitState] [nvarchar](255) NULL
);

--Insert data into Temp Table
INSERT INTO [#Nashville Housing] 
SELECT * FROM [Nashville Housing];

-- Identify and delete duplicate records using CTE
WITH NashvilleHousing_CTE AS (
    SELECT *, 
           ROW_NUMBER() OVER(PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference ORDER BY UniqueID) row_num
    FROM [#Nashville Housing]
)
DELETE FROM NashvilleHousing_CTE
WHERE row_num > 1;

--Drop unused columns
ALTER TABLE [#Nashville Housing]
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate;

--Verify final table
SELECT * FROM [#Nashville Housing];
