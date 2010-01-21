CREATE TABLE "fhv_classes" (
"id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL DEFAULT NULL,
"package_id" INTEGER DEFAULT NULL,
"ident" TEXT DEFAULT NULL,
"name" TEXT DEFAULT NULL,
"summary" TEXT DEFAULT NULL,
"detail" TEXT DEFAULT NULL,
"type" INTEGER DEFAULT NULL);

CREATE TABLE "fhv_packages" (
"id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL DEFAULT NULL,
"ident" TEXT DEFAULT NULL,
"name" TEXT DEFAULT NULL,
"summary" TEXT DEFAULT NULL);

CREATE TABLE "fhv_signatures" (
"id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL DEFAULT NULL,
"parent_id" INTEGER DEFAULT NULL,
"parent_type" INTEGER,
"parent_name" TEXT DEFAULT NULL, 
"ident" TEXT DEFAULT NULL,
"name" TEXT DEFAULT NULL,
"signature" TEXT DEFAULT NULL,
"summary" TEXT DEFAULT NULL,
"detail" TEXT DEFAULT NULL,
"inherited" INTEGER DEFAULT NULL,
"type" INTEGER DEFAULT NULL);

CREATE INDEX "idx_classes_name" ON "fhv_classes" ("name");
CREATE INDEX "idx_signatures_name" ON "fhv_signatures" ("name");
CREATE INDEX "idx_signatures_parent_id" ON "fhv_signatures" ("parent_id");