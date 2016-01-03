=begin license

Copyright (c) 2016 Maxim Noah Khailo, All Rights Reserved

This file is part of PKafka.

PKafka is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

PKafka is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with PKafka.  If not, see <http://www.gnu.org/licenses/>.
use NativeCall;

=end license

use NativeCall;
use PKafka::Native;
use PKafka::Kafka;
use PKafka::Config;

class PKafka::Producer 
{
    has Pointer $!topic;
    has PKafka::Kafka $!kafka;
    has $!config;
    has $!topic-config;

    method topic { PKafka::rd_kafka_topic_name($!topic);}

    submethod BUILD(
        Str :$topic!, 
        PKafka::Config :$config, 
        PKafka::TopicConfig :$topic-config,
        Str :$brokers!) 
    {
        $!config = $config ?? $config !! PKafka::Config.new;
        $!topic-config = $topic-config ?? $topic-config !! PKafka::TopicConfig.new; 

        $!kafka = PKafka::Kafka.new( type=>PKafka::RD_KAFKA_PRODUCER, conf=>$!config);
        PKafka::gaurded_rd_kafka_brokers_add($!kafka.handle, $brokers);
        $!topic = PKafka::rd_kafka_topic_new($!kafka.handle, $topic, $!topic-config.handle);
    }

    multi method put(Str $payload) 
    {
        self.put(payload=>$payload);
    }

    multi method put(Blob $payload) 
    {
        self.put(payload=>$payload);
    }

    multi method put( Int :$partition, Str :$payload, Str :$key) 
    {
        self.put(partition=>$partition, payload=>$payload.encode("UTF-8"), key=>$key)
    }

    multi method put( Int :$partition, Blob :$payload, Str :$key) 
    {
        my $p = PKafka::RD_KAFKA_PARTITION_UA;
        with $partition { $p = $partition; }

        my int $msgops = PKafka::RD_KAFKA_MSG_F_COPY;
        my Pointer $msg-opaque := Pointer.new;

        my $res = PKafka::rd_kafka_produce(
            $!topic, $p, $msgops,
            $payload, $payload.elems, $key, $key.elems, $msg-opaque);

        die "Error producing message to partition $partition for topic { self.topic}: {PKafka::errno2str}" if $res == -1;
    }

    submethod DESTROY { PKafka::rd_kafka_topic_destroy($!topic) }
}