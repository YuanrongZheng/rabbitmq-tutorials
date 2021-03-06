#import "ViewController.h"
@import RMQClient;

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self receiveLogsTopic:@[@"kern.*", @"*.critical"]];
    sleep(1);
    [self emitLogTopic:@"Hello World!" routingKey:@"kern.info"];
    [self emitLogTopic:@"A critical kernel error" routingKey:@"kern.critical"];
    [self emitLogTopic:@"Critical module error" routingKey:@"somemod.critical"];
    [self emitLogTopic:@"Just some module info. You won't get this." routingKey:@"somemod.info"];
}

- (void)receiveLogsTopic:(NSArray *)routingKeys {
    RMQConnection *conn = [[RMQConnection alloc] initWithDelegate:[RMQConnectionDelegateLogger new]];
    [conn start];

    id<RMQChannel> ch = [conn createChannel];
    RMQExchange *x    = [ch topic:@"topic_logs"];
    RMQQueue *q       = [ch queue:@"" options:RMQQueueDeclareExclusive];

    for (NSString *routingKey in routingKeys) {
        [q bind:x routingKey:routingKey];
    }

    NSLog(@"Waiting for logs.");

    [q subscribe:^(RMQDeliveryInfo * _Nonnull deliveryInfo, RMQMessage * _Nonnull message) {
        NSLog(@"%@:%@", deliveryInfo.routingKey, message.content);
    }];
}

- (void)emitLogTopic:(NSString *)msg routingKey:(NSString *)routingKey {
    RMQConnection *conn = [[RMQConnection alloc] initWithDelegate:[RMQConnectionDelegateLogger new]];
    [conn start];

    id<RMQChannel> ch = [conn createChannel];
    RMQExchange *x    = [ch topic:@"topic_logs"];

    [x publish:msg routingKey:routingKey];
    NSLog(@"Sent '%@'", msg);

    [conn close];
}

@end
