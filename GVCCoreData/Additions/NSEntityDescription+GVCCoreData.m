//
//  NSEntityDescription+GVCCoreData.m
//
//  Created by David Aspinall on 24/08/09.
//  Copyright 2010 Global Village Consulting Inc. All rights reserved.
//

#import "NSEntityDescription+GVCCoreData.h"
#import "NSManagedObject+GVCCoreData.h"
#import "GVCManagedObject.h"
#import "NSPropertyDescription+GVCCoreData.h"
/**
 * $Date: 2009-01-20 16:28:51 -0500 (Tue, 20 Jan 2009) $
 * $Rev: 121 $
 * $Author: david $
*/
@implementation NSEntityDescription (GVCCoreData)

- (NSString *)gvc_localizedName
{
    NSString *key = GVC_SPRINTF(@"Entity/%@", [self name]);
    NSDictionary *dictionary = [[self managedObjectModel] localizationDictionary];
    NSString *localizedName = [dictionary objectForKey:key];
    if ( gvc_IsEmpty(localizedName) == YES )
    {
        localizedName = GVC_LocalizedString(key, [self name]);
    }
    return (localizedName ? localizedName : [self name]);
}

- (NSString *)gvc_localizedNameForProperty:(NSString *)propname
{
    NSPropertyDescription *prop = [[self propertiesByName] objectForKey:propname];
    return (prop == nil ? nil : [prop gvc_localizedName]);
}

- (NSString *)gvc_localizedErrorString:(NSString *)errorMessage
{
    NSString *key = GVC_SPRINTF(@"ErrorString/%@", errorMessage);
    NSDictionary *dictionary = [[self managedObjectModel] localizationDictionary];
    NSString *localizedName = [dictionary objectForKey:key];
    if ( gvc_IsEmpty(localizedName) == YES )
    {
        localizedName = GVC_LocalizedString(key, errorMessage);
    }
    return (localizedName ? localizedName : errorMessage);
}

- (NSPredicate *)gvc_predicateForProperty:(NSString *)key andValue:(NSObject *)val
{
	NSPredicate *predicate = nil;
	NSAttributeDescription *attribute = [self gvc_attributeNamed:key];
	NSRelationshipDescription *relationship = [self gvc_relationshipNamed:key];
	if ( attribute != nil )
	{
		if ( val == nil )
		{
			predicate = [NSPredicate predicateWithFormat:@"(%K == nil)", [attribute name]];
		}
		else if ([attribute attributeType] == NSStringAttributeType)
		{
			predicate = [NSPredicate predicateWithFormat:@"%K LIKE[c] %@", [attribute name], val];
		}
		else
		{
			predicate = [NSPredicate predicateWithFormat:@"%K == %@", [attribute name], val];
		}
	}
	else if ( relationship != nil )
	{
		if ( val == nil )
		{
			predicate = [NSPredicate predicateWithFormat:@"(%K == nil)", [relationship name]];
		}
		else
		{
			predicate = [NSPredicate predicateWithFormat:@"%K == %@", [relationship name], val];
		}
	}
	return predicate;
}

- (NSSortDescriptor *)gvc_defaultSortDescriptor
{
	NSArray *all = [[self attributesByName] allKeys];
	NSArray *def = [NSArray arrayWithObjects:GVCManagedObject_SORT_ORDER_ATTRIBUTE, GVCManagedObject_NAME_ATTRIBUTE, GVCManagedObject_SYNC_ID_ATTRIBUTE, [all objectAtIndex:0], nil];
	
	NSSortDescriptor *sort = nil;
	for ( NSUInteger i = 0; (i < [def count]) && (sort == nil); i++ )
	{
		NSString *attName = [def objectAtIndex:i];
		if ( [all indexOfObject:attName] != NSNotFound )
		{
			sort = [[NSSortDescriptor alloc] initWithKey:attName ascending:YES];
		}
	}
	
	GVC_ASSERT(sort != nil, @"Unable to find default sort in %@", all );

	return sort;
}

- (NSPropertyDescription *)gvc_propertyNamed:(NSString *)attributeName
{
	NSDictionary *properties = [self propertiesByName];
	return [properties objectForKey:attributeName];
}

- (NSAttributeDescription *)gvc_attributeNamed:(NSString *)attributeName
{
	NSPropertyDescription *prop = [self gvc_propertyNamed:attributeName];
	
	if ([prop isKindOfClass:[NSAttributeDescription class]] == NO )
		return nil;
	
	return (NSAttributeDescription *)prop;
}

- (NSRelationshipDescription *)gvc_relationshipNamed:(NSString *)attributeName
{
	NSPropertyDescription *prop = [self gvc_propertyNamed:attributeName];
	
	if ([prop isKindOfClass:[NSRelationshipDescription class]] == NO )
		return nil;
	
	return (NSRelationshipDescription *)prop;
}

/* this keypath usually ends in an Attribute, but it can be a relationship
 */
- (NSPropertyDescription *)gvc_propertyNamedKeypath:(NSString *)attributePath
{
	NSPropertyDescription *property = nil;
	NSEntityDescription *current = self;
	NSArray *path = [attributePath componentsSeparatedByString:@"."];
	for ( NSString *step in path )
	{
        if ( [path indexOfObject:step] == ([path count] - 1) )
        {
            // last step, preperty is whatever this points to
            property = [current gvc_propertyNamed:step];
        }
        else
        {
            // not the last step, so it MUST be a relationship
            NSRelationshipDescription *relation = [current gvc_relationshipNamed:step];
            GVC_ASSERT_NOT_NIL(relation);
            
            current = [relation destinationEntity];
        }
	}
	return property;
}

- (NSAttributeDescription *)gvc_attributeNamedKeypath:(NSString *)attributePath
{
    NSPropertyDescription *property = [self gvc_propertyNamedKeypath:attributePath];
	return (NSAttributeDescription *)(([property isKindOfClass:[NSAttributeDescription class]] == YES) ? property : nil );
}

- (NSRelationshipDescription *)gvc_relationshipNamedKeypath:(NSString *)relationPath
{
    NSPropertyDescription *property = [self gvc_propertyNamedKeypath:relationPath];
	return (NSRelationshipDescription *)(([property isKindOfClass:[NSRelationshipDescription class]] == YES) ? property : nil );
}

- (NSArray *)gvc_allAttributes
{
    return [[self properties] gvc_filterForClass:[NSAttributeDescription class]];
}

- (NSArray *)gvc_allRelationships
{
    return [[self properties] gvc_filterForClass:[NSRelationshipDescription class]];    
}

@end
