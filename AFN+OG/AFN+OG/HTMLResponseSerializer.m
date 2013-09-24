#import "HTMLResponseSerializer.h"

@implementation HTMLResponseSerializer

-(id)responseObjectForResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError *__autoreleasing *)error
{
    return [ObjectiveGumbo parseDocumentWithData:data];
}

@end
