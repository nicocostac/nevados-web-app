-- First add the new columns
ALTER TABLE client_addresses
ADD COLUMN borough_id UUID REFERENCES boroughs(id),
ADD COLUMN neighborhood_id UUID REFERENCES neighborhoods(id);

-- Update existing records to match their borough and neighborhood names
UPDATE client_addresses ca
SET 
  borough_id = b.id,
  neighborhood_id = n.id
FROM boroughs b, neighborhoods n
WHERE 
  ca.borough = b.name 
  AND ca.neighborhood = n.name
  AND n.borough_id = b.id;

-- After data is migrated, drop the old columns
ALTER TABLE client_addresses
DROP COLUMN borough,
DROP COLUMN neighborhood; 