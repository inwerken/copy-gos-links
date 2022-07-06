# copy-gos-attachment-links
Copy GOS attachments links to other object

# Business partner
When changing from the old customer master (KNA1) and vendor master (LFA1) to the new business partners, then the linked GOS (Generic Object Services) attachments are not copied or transferred to the corresponding business partner.

This simple report reads the attachment links for an object and copies the link to a new object type.

## class helper

helper class for additional functions of main class

### method get_new_id

To copy the attachment link to an new object, the program needs to know the target object number. The method get_new_id delivers the new number.
