import org.apache.flink.api.common.functions.MapFunction;
import org.apache.flink.streaming.api.datastream.DataStreamSource;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;

public class FlinkJavaExample {
    public static void main(String[] args) throws Exception {
        StreamExecutionEnvironment environment =
                StreamExecutionEnvironment.getExecutionEnvironment();
        environment.setParallelism(1);

        DataStreamSource<Integer> numbers = environment.fromData(1, 2, 3, 4, 5);

        numbers
                .filter(value -> value % 2 == 0)
                .map((MapFunction<Integer, Integer>) value -> value * 2)
                .returns(Integer.class)
                .print();

        environment.execute("java-example");
    }
}
