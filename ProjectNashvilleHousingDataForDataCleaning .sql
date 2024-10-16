-- Cleaning Data in SQL Queries

 SELECT *
 FROM PortofolioProject.nashvilleHousingDataForDataCleaning;
 
-- Populate Property Address Data

SELECT a.ParcelID, a.PropertyAddress,b.ParcelID,b.PropertyAddress, 
COALESCE(a.PropertyAddress,b.PropertyAddress)
FROM PortofolioProject.nashvilleHousingDataForDataCleaning AS a
JOIN PortofolioProject.nashvilleHousingDataForDataCleaning AS b 
ON a.ParcelID = b.ParcelID
AND a.UniqueID <>b.UniqueID
WHERE a.PropertyAddress IS NULL OR TRIM(a.PropertyAddress) = '';

SET SQL_SAFE_UPDATES = 0;

UPDATE PortofolioProject.nashvilleHousingDataForDataCleaning AS a
JOIN PortofolioProject.nashvilleHousingDataForDataCleaning AS b
ON a.ParcelID = b.ParcelID
AND a.UniqueID <> b.UniqueID
SET a.PropertyAddress = COALESCE(b.PropertyAddress, a.PropertyAddress)
WHERE a.PropertyAddress IS NULL OR TRIM(a.PropertyAddress) = '';

SET SQL_SAFE_UPDATES = 1;

-- Breaking Out Address into Indicidual Columns (Adress, City, State)

-- Split PropertyAddress

SELECT PropertyAddress
FROM PortofolioProject.nashvilleHousingDataForDataCleaning
WHERE a.PropertyAddress IS NULL OR TRIM(a.PropertyAddress) = ''
ORDER BY ParcelID;

SELECT 
SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress)-1) AS Address,
SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress) +1, LENGTH(PropertyAddress)) AS Address
FROM PortofolioProject.nashvilleHousingDataForDataCleaning;

ALTER TABLE nashvilleHousingDataForDataCleaning
ADD PropertySplitAddress VARCHAR(255);

SET SQL_SAFE_UPDATES = 0;

UPDATE nashvilleHousingDataForDataCleaning
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress)-1);

SET SQL_SAFE_UPDATES = 1;

ALTER TABLE nashvilleHousingDataForDataCleaning
ADD PropertySplitCity VARCHAR(255);

SET SQL_SAFE_UPDATES = 0;

UPDATE nashvilleHousingDataForDataCleaning
SET PropertySplitCity = SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress) +1, LENGTH(PropertyAddress));

SET SQL_SAFE_UPDATES = 1;

SELECT *
FROM PortofolioProject.nashvilleHousingDataForDataCleaning;

-- Split OwnerAddress
 
SELECT OwnerAddress
FROM PortofolioProject.nashvilleHousingDataForDataCleaning;
SELECT 
SUBSTRING_INDEX(REPLACE(OwnerAddress, ',', '.'), '.', 1) ,
SUBSTRING_INDEX(SUBSTRING_INDEX(REPLACE(OwnerAddress, ',', '.'), '.', 2), '.', -1) ,
SUBSTRING_INDEX(SUBSTRING_INDEX(REPLACE(OwnerAddress, ',', '.'), '.', 3), '.', -1)
FROM PortofolioProject.nashvilleHousingDataForDataCleaning;

ALTER TABLE nashvilleHousingDataForDataCleaning
ADD OwnerSplitAddress VARCHAR(255);

SET SQL_SAFE_UPDATES = 0;

UPDATE nashvilleHousingDataForDataCleaning
SET OwnerSplitAddress = SUBSTRING_INDEX(REPLACE(OwnerAddress, ',', '.'), '.', 1);

SET SQL_SAFE_UPDATES = 1;

ALTER TABLE nashvilleHousingDataForDataCleaning
ADD OwnerSplitCity VARCHAR(255);

SET SQL_SAFE_UPDATES = 0;

UPDATE nashvilleHousingDataForDataCleaning
SET OwnerSplitCity = SUBSTRING_INDEX(SUBSTRING_INDEX(REPLACE(OwnerAddress, ',', '.'), '.', 2), '.', -1);

SET SQL_SAFE_UPDATES = 1;

ALTER TABLE nashvilleHousingDataForDataCleaning
ADD OwnerSplitState VARCHAR(255);

SET SQL_SAFE_UPDATES = 0;

UPDATE nashvilleHousingDataForDataCleaning
SET OwnerSplitState = SUBSTRING_INDEX(SUBSTRING_INDEX(REPLACE(OwnerAddress, ',', '.'), '.', 3), '.', -1);

SET SQL_SAFE_UPDATES = 1;

SELECT *
FROM PortofolioProject.nashvilleHousingDataForDataCleaning;

-- Change Y and N to Yes and No in "Sold as Vacant" field

SELECT DISTINCT(SoldAsVacant),COUNT(SoldAsVacant)
FROM PortofolioProject.nashvilleHousingDataForDataCleaning
GROUP BY SoldAsVacant
ORDER BY 2;

SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
WHEN SoldAsVacant = 'N' THEN 'No'
ELSE SoldAsVacant
END
FROM PortofolioProject.nashvilleHousingDataForDataCleaning;

SET SQL_SAFE_UPDATES = 0;

UPDATE nashvilleHousingDataForDataCleaning
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
WHEN SoldAsVacant = 'N' THEN 'No'
ELSE SoldAsVacant
END;
SET SQL_SAFE_UPDATES = 1;


-- Remove Duplicates  

WITH RowNumCTE AS (
SELECT *, 
	ROW_NUMBER() OVER( 
    PARTITION BY ParcelID,
				PropertyAddress,
                SalePrice,
				SaleDate,
                LegalReference
                ORDER BY UniqueID
                    ) AS row_num

FROM PortofolioProject.nashvilleHousingDataForDataCleaning
-- ORDER BY ParcelID;
)

SELECT *
FROM RowNumCTE
WHERE row_num >1
ORDER BY PropertyAddress;

SET SQL_SAFE_UPDATES = 0;
DELETE 
FROM PortofolioProject.nashvilleHousingDataForDataCleaning
WHERE UniqueID IN(
	SELECT UniqueID
    FROM (
		SELECT UniqueID,
        	ROW_NUMBER() OVER( 
			PARTITION BY ParcelID,
						 PropertyAddress,
						 SalePrice,
						 SaleDate,
						 LegalReference
			ORDER BY UniqueID
			) AS row_num
		FROM PortofolioProject.nashvilleHousingDataForDataCleaning
	)AS duplicates
    WHERE row_num >1
);
SET SQL_SAFE_UPDATES = 1;


-- Delete Unsed Colimns (very very rare)

SELECT *
FROM PortofolioProject.nashvilleHousingDataForDataCleaning;

ALTER TABLE PortofolioProject.nashvilleHousingDataForDataCleaning
DROP COLUMN OwnerAddress,
DROP COLUMN TaxDistrict,
DROP COLUMN PropertyAddress;
