package app.demo.todo.unit;

import app.demo.todo.utils.Utils;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

public class TodoUtilsTest {

    @Test
    @DisplayName("Shorten String test")
    void shortenStringTest() {
        assertEquals("Test...", Utils.shortenString("TestString", 7));
        assertEquals("Test...", Utils.shortenString("TestString"));
        assertEquals("Test", Utils.shortenString("Test"));
        assertEquals("Test", Utils.shortenString("Test", 7));
        assertEquals("Test", Utils.shortenString("Test", 4));
        assertEquals("Testa", Utils.shortenString("Testa"));
        assertEquals("Testa", Utils.shortenString("Testa", 5));
        assertEquals("Testab", Utils.shortenString("Testab"));
        assertEquals("Testab", Utils.shortenString("Testab", 7));
    }

}
