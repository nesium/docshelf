CREATE INDEX "idx_classes" ON "fhv_classes" ("name", "package_id");
CREATE INDEX "idx_signatures_sorting" ON "fhv_signatures" ("parent_id","parent_type","name","inherited","type");