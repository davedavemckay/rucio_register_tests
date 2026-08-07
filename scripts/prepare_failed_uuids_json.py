import argparse
import os
import sys

start_failure_list = "=== RUCIO_REGISTER_FAILED_UUIDS_START ==="
end_failure_list = "=== RUCIO_REGISTER_FAILED_UUIDS_END ==="

def prepare_failed_uuids_json(
    input_filename=""
):
    assert input_filename is not "", "Error input_filename is empty"
    output_filename = os.path.dirname(input_filename)+"/"+"_".join(input_filename.split("/")[-1].split(".")[0:-1]) + "_failed_uuids.json"
    with open(input_filename, "r") as input_file, open(output_filename, "w") as output_file:
        content = input_file.read()
        start_index = content.find(start_failure_list)
        end_index = content.find(end_failure_list)
        if start_index == -1 or end_index == -1:
            raise ValueError("start_failure_list or end_failure_list not found in input_filename")
        start_index += len(start_failure_list)
        uuids_json = content[start_index:end_index]
        output_file.write(uuids_json)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Prepare failed uuids json")
    parser.add_argument("--input-filename", "-i", dest="input_filename", type=str, required=True, help="Input filename")
    args = parser.parse_args()
    input_filename = args.input_filename
    print(input_filename)
    try:
        prepare_failed_uuids_json(args.input_filename)
    except AssertionError as e:
        print(e)
        sys.exit(10, f"Assertion Error: {e}")
    except ValueError as e:
        print(e)
        sys.exit(20, f"Value Error: {e}")
    except FileNotFoundError as e:
        print(e)
        sys.exit(30, f"File Not Found Error: {e}")
    except Exception as e:
        print(e)
        sys.exit(40, f"Error: {e}")