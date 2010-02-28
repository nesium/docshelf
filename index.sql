CREATE INDEX "idx_classes_name" ON "fhv_classes" ("name");
CREATE INDEX "idx_signatures_sorting" ON "fhv_signatures" ("parent_id","parent_type","name","inherited","type");