from pyflink.common import Types
from pyflink.datastream import StreamExecutionEnvironment


def main() -> None:
    env = StreamExecutionEnvironment.get_execution_environment()
    env.set_parallelism(1)

    numbers = env.from_collection(
        [1, 2, 3, 4, 5],
        type_info=Types.INT(),
    )

    doubled_even_numbers = numbers.filter(lambda value: value % 2 == 0).map(
        lambda value: value * 2,
        output_type=Types.INT(),
    )

    doubled_even_numbers.print()
    env.execute("python-example")


if __name__ == "__main__":
    main()
