from pyspark.sql import SparkSession
from pyspark.sql.functions import col, sum, desc

def main():
    """
    主函数，演示使用 RAPIDS 加速的 Spark 数据处理流程。
    """
    # --- 1. 初始化 SparkSession ---
    # 配置 RAPIDS 插件并指定使用 GPU 0
    spark = SparkSession.builder \
        .appName("SparkRapidsDemo") \
        .master("local[*]") \
        .config("spark.plugins", "com.nvidia.spark.SQLPlugin") \
        .config("spark.jars", "/root/spark_rapids_dev/source/rapids-4-spark_2.12-25.06.0.jar") \
        .config("spark.rapids.sql.enabled", "true") \
        .config("spark.rapids.sql.explain", "ALL") \
        .config("spark.executorEnv.CUDA_VISIBLE_DEVICES", "0") \
        .getOrCreate()
        # .config("spark.executorEnv.CUDA_VISIBLE_DEVICES", "0")设置无效，请使用export CUDA_VISIBLE_DEVICES=0

    # --- 2. 数据读取 ---
    # 从 CSV 文件读取销售和产品数据
    # 使用 inferSchema=True 让 Spark 自动推断数据类型
    print("正在读取数据...")
    sales_df = spark.read.csv("sales.csv", header=True, inferSchema=True)
    products_df = spark.read.csv("products.csv", header=True, inferSchema=True)

    # --- 3. 转换 (Transformation) ---
    print("开始数据转换...")

    # a. 连接 (Join)
    # 将销售数据和产品数据通过 product_id 连接
    joined_df = sales_df.join(products_df, "product_id")

    # b. 过滤 (Filter / Where)
    # 筛选出 category_id 为 1 且 sale_amount 大于 500 的记录
    filtered_df = joined_df.filter(
        (col("category_id") == 1) & (col("sale_amount") > 500)
    )

    # c. 聚合 (GroupBy / Agg)
    # 按产品名称和品类 ID 分组，计算总销售额
    aggregated_df = filtered_df.groupBy("product_name", "category_id") \
        .agg(sum("sale_amount").alias("total_sales"))

    # d. 排序 (OrderBy)
    # 按总销售额降序排序
    sorted_df = aggregated_df.orderBy(desc("total_sales"))
    
    # e. 投影/选择列 (Select)
    # 选择最终需要的列
    final_df = sorted_df.select("product_name", "category_id", "total_sales")
    
    print("数据转换完成。")

    # --- 4. 打印结果和执行计划 ---
    print("显示最终结果:")
    final_df.show()

    print("打印执行计划以确认 RAPIDS 加速:")
    final_df.explain()

    # --- 5. 数据写入 ---
    # 将结果以 Parquet 格式写入磁盘，覆盖已有文件
    output_path = "output_report.parquet"
    print(f"正在将结果写入到 {output_path}...")
    final_df.write.mode("overwrite").parquet(output_path)
    print("数据写入完毕。")

    # --- 6. 停止 SparkSession ---
    input()
    spark.stop()
    print("SparkSession 已停止。")

if __name__ == "__main__":
    main() 