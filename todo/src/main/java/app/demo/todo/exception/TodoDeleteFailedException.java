package app.demo.todo.exception;

public class TodoDeleteFailedException extends RuntimeException{
    private String technicalDetail;

    public TodoDeleteFailedException(String technicalDetail) {
        super(String.format("Todo delete failed"));
        this.technicalDetail = technicalDetail;
    }

    public String getTechnicalDetail() {
        return technicalDetail;
    }
}
