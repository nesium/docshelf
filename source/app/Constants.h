/*
 *  Constants.h
 *  EarthDocs
 *
 *  Created by Marc Bauer on 23.01.10.
 *  Copyright 2010 nesiumdotcom. All rights reserved.
 *
 */

typedef enum _FHVItemType{
	kItemTypePackage = 1, 
	kItemTypeClass = 2, 
	kItemTypeSignature = 3
} FHVItemType;

typedef enum _FHVDocSetSearchMode{
	kFHVDocSetSearchModeContains = 0,
	kFHVDocSetSearchModePrefix = 1, 
	kFHVDocSetSearchModeExact = 2
} FHVDocSetSearchMode;

typedef enum _FHVSignatureParentType{
	kSigParentTypePackage = 0, 
	kSigParentTypeClass = 1
} FHVSignatureParentType;

typedef enum _FHVSignatureType{
	kSigTypeFunction = 0, 
	kSigTypeVariable = 1, 
	kSigTypeConstant = 2, 
	kSigTypeEvent = 3
} FHVSignatureType;

typedef enum _FHVClassType{
	kClassTypeClass = 0, 
	kClassTypeInterface = 1
} FHVClassType;